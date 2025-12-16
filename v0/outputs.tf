output "bucket_name" {
  value       = aws_s3_bucket.thanos.id
  description = "Name of the Thanos S3 bucket"
}

output "bucket_arn" {
  value       = aws_s3_bucket.thanos.arn
  description = "ARN of the Thanos S3 bucket"
}

output "bucket_regional_domain_name" {
  value       = aws_s3_bucket.thanos.bucket_regional_domain_name
  description = "Regional domain name of the Thanos S3 bucket"
}

output "iam_role_arn" {
  value       = aws_iam_role.thanos.arn
  description = "ARN of the Thanos IAM role for IRSA"
}

output "iam_role_name" {
  value       = aws_iam_role.thanos.name
  description = "Name of the Thanos IAM role"
}

output "writer_role_arns" {
  value       = { for k, v in aws_iam_role.thanos_writer : k => v.arn }
  description = "Map of writer role names to ARNs"
}

output "writer_role_names" {
  value       = { for k, v in aws_iam_role.thanos_writer : k => v.name }
  description = "Map of writer role names"
}

output "dns_hostname" {
  value       = var.enable_dns ? var.dns_hostname : null
  description = "DNS hostname for Thanos (if enabled)"
}
