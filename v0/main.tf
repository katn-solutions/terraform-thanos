# Local variables
locals {
  bucket_name   = "${var.organization}-thanos-${var.cluster_name}-${var.environment}"
  iam_role_name = "${var.organization}-thanos-${var.cluster_name}-${var.environment}"

  # Combine primary service account with additional ones
  all_service_accounts = concat(
    [{
      namespace = var.service_account_namespace
      name      = var.service_account_name
    }],
    var.additional_service_accounts
  )

  common_tags = merge(
    {
      Organization = var.organization
      Cluster      = var.cluster_name
      Environment  = var.environment
      Service      = "thanos"
    },
    var.tags
  )
}

# S3 Bucket
resource "aws_s3_bucket" "thanos" {
  bucket = local.bucket_name
  tags   = local.common_tags
}

# S3 Bucket Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "thanos" {
  count  = var.enable_encryption ? 1 : 0
  bucket = aws_s3_bucket.thanos.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "thanos" {
  bucket = aws_s3_bucket.thanos.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "thanos" {
  bucket = aws_s3_bucket.thanos.id

  rule {
    id     = "expire-metrics"
    status = "Enabled"

    filter {}

    expiration {
      days = var.lifecycle_retention_days
    }
  }
}

# IAM Role for Thanos (primary cluster with IRSA)
resource "aws_iam_role" "thanos" {
  name = local.iam_role_name
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for sa in local.all_service_accounts : {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider_url}:sub" = "system:serviceaccount:${sa.namespace}:${sa.name}"
            "${var.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# IAM Policy for Thanos (full access)
resource "aws_iam_policy" "thanos" {
  name = "${local.iam_role_name}-policy"
  tags = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:PutObject",
          "s3:CreateBucket"
        ]
        Resource = [
          aws_s3_bucket.thanos.arn,
          "${aws_s3_bucket.thanos.arn}/*"
        ]
      }
    ]
  })
}

# IAM Role Policy Attachment
resource "aws_iam_role_policy_attachment" "thanos" {
  policy_arn = aws_iam_policy.thanos.arn
  role       = aws_iam_role.thanos.name
}

# IAM Policy for Writer Roles (write-only, no delete)
resource "aws_iam_policy" "thanos_writer" {
  count = length(var.additional_writer_roles) > 0 ? 1 : 0
  name  = "${var.organization}-thanos-writer-${var.environment}"
  tags  = local.common_tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject",
          "s3:CreateBucket"
        ]
        Resource = [
          aws_s3_bucket.thanos.arn,
          "${aws_s3_bucket.thanos.arn}/*"
        ]
      }
    ]
  })
}

# IAM Roles for Additional Writer Clusters
resource "aws_iam_role" "thanos_writer" {
  for_each = { for role in var.additional_writer_roles : role.name => role }

  name = "${var.organization}-thanos-writer-${each.value.name}"
  tags = merge(
    local.common_tags,
    {
      WriterCluster = each.value.name
    }
  )

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = each.value.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${each.value.oidc_provider_url}:sub" = "system:serviceaccount:${each.value.service_account_namespace}:${each.value.service_account_name}"
            "${each.value.oidc_provider_url}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })
}

# Attach Writer Policy to Writer Roles
resource "aws_iam_role_policy_attachment" "thanos_writer" {
  for_each = { for role in var.additional_writer_roles : role.name => role }

  policy_arn = aws_iam_policy.thanos_writer[0].arn
  role       = aws_iam_role.thanos_writer[each.key].name
}

# DNS - Cloudflare
resource "cloudflare_record" "thanos" {
  count   = var.enable_dns && var.dns_provider == "cloudflare" ? 1 : 0
  zone_id = var.dns_zone_id
  type    = "CNAME"
  name    = var.dns_hostname
  value   = aws_s3_bucket.thanos.bucket_regional_domain_name
  proxied = false
  ttl     = 60
}

# DNS - Route53
resource "aws_route53_record" "thanos" {
  count   = var.enable_dns && var.dns_provider == "route53" ? 1 : 0
  zone_id = var.dns_zone_id
  name    = var.dns_hostname
  type    = "CNAME"
  ttl     = 60
  records = [aws_s3_bucket.thanos.bucket_regional_domain_name]
}
