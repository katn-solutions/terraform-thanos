# terraform-thanos

Terraform module for provisioning AWS infrastructure to support Thanos object storage for Prometheus metrics.

## Overview

This module creates the necessary AWS resources for Thanos to store Prometheus metrics in S3:

- S3 bucket for metrics storage with lifecycle policies
- S3 encryption and public access blocking
- IAM roles with IRSA (IAM Roles for Service Accounts) for Kubernetes pod authentication
- Support for multi-cluster metrics federation with separate writer roles
- Optional DNS records (Cloudflare or Route53)

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.1.7, < 2.0.0 |
| aws | >= 5.39.0, < 6.0.0 |
| cloudflare | 4.8.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 5.39.0, < 6.0.0 |
| cloudflare | 4.8.0 |

## Usage

### Basic Single Cluster Setup

```hcl
module "thanos" {
  source = "git::https://github.com/katn-solutions/terraform-thanos.git//v0?ref=v1.0.0"

  organization = "myorg"
  cluster_name = "prod-cluster"
  environment  = "prod"

  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE44F"
  oidc_provider_url = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLED539D4633E53DE44F"

  service_account_namespace = "monitoring"
  service_account_name      = "thanos-store"

  lifecycle_retention_days = 7

  tags = {
    Team = "platform"
  }
}
```

### Multi-Cluster Federation Setup

```hcl
module "thanos" {
  source = "git::https://github.com/katn-solutions/terraform-thanos.git//v0?ref=v1.0.0"

  organization = "myorg"
  cluster_name = "central"
  environment  = "prod"

  # Primary cluster OIDC
  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/CENTRAL"
  oidc_provider_url = "oidc.eks.us-west-2.amazonaws.com/id/CENTRAL"

  service_account_namespace = "monitoring"
  service_account_name      = "thanos-store"

  # Additional service accounts for primary cluster
  additional_service_accounts = [
    {
      namespace = "monitoring"
      name      = "prometheus-k8s"
    }
  ]

  # Writer roles for remote clusters
  additional_writer_roles = [
    {
      name                      = "us-east-1"
      oidc_provider_arn         = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/EAST"
      oidc_provider_url         = "oidc.eks.us-east-1.amazonaws.com/id/EAST"
      service_account_namespace = "monitoring"
      service_account_name      = "prometheus-k8s"
    },
    {
      name                      = "eu-west-1"
      oidc_provider_arn         = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/EU"
      oidc_provider_url         = "oidc.eks.eu-west-1.amazonaws.com/id/EU"
      service_account_namespace = "monitoring"
      service_account_name      = "prometheus-k8s"
    }
  ]

  lifecycle_retention_days = 5
}
```

### With DNS

```hcl
module "thanos" {
  source = "git::https://github.com/katn-solutions/terraform-thanos.git//v0?ref=v1.0.0"

  organization = "myorg"
  cluster_name = "prod-cluster"
  environment  = "prod"

  oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE"
  oidc_provider_url = "oidc.eks.us-west-2.amazonaws.com/id/EXAMPLE"

  # DNS configuration
  enable_dns    = true
  dns_provider  = "cloudflare"
  dns_zone_id   = "your-zone-id"
  dns_hostname  = "thanos-metrics.example.com"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| organization | Organization name for resource naming | `string` | n/a | yes |
| cluster_name | Name of the Kubernetes cluster | `string` | n/a | yes |
| environment | Environment (dev/staging/prod) | `string` | n/a | yes |
| oidc_provider_arn | ARN of the EKS OIDC provider | `string` | n/a | yes |
| oidc_provider_url | URL of the EKS OIDC provider (without https://) | `string` | n/a | yes |
| service_account_namespace | Kubernetes namespace for Thanos service account | `string` | `"monitoring"` | no |
| service_account_name | Kubernetes service account name for Thanos | `string` | `"thanos-store"` | no |
| additional_service_accounts | Additional service accounts for the primary IAM role | `list(object)` | `[]` | no |
| additional_writer_roles | Additional writer roles for multi-cluster setup | `list(object)` | `[]` | no |
| lifecycle_retention_days | S3 lifecycle retention in days | `number` | `5` | no |
| enable_encryption | Enable S3 bucket encryption | `bool` | `true` | no |
| tags | Additional tags for resources | `map(string)` | `{}` | no |
| enable_dns | Enable DNS record creation | `bool` | `false` | no |
| dns_hostname | DNS hostname for Thanos (required if enable_dns=true) | `string` | `""` | no |
| dns_provider | DNS provider to use (cloudflare or route53) | `string` | `"cloudflare"` | no |
| dns_zone_id | DNS Zone ID (Cloudflare Zone ID or Route53 Hosted Zone ID) | `string` | `""` | no |

## Outputs

| Name | Description |
|------|-------------|
| bucket_name | Name of the Thanos S3 bucket |
| bucket_arn | ARN of the Thanos S3 bucket |
| bucket_regional_domain_name | Regional domain name of the Thanos S3 bucket |
| iam_role_arn | ARN of the Thanos IAM role for IRSA |
| iam_role_name | Name of the Thanos IAM role |
| writer_role_arns | Map of writer role names to ARNs |
| writer_role_names | Map of writer role names |
| dns_hostname | DNS hostname for Thanos (if enabled) |

## Kubernetes Integration

After creating the infrastructure, annotate your Kubernetes ServiceAccount with the IAM role ARN:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: thanos-store
  namespace: monitoring
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/myorg-thanos-prod-cluster-prod
```

Configure Thanos to use the S3 bucket:

```yaml
type: s3
config:
  bucket: myorg-thanos-prod-cluster-prod
  endpoint: s3.us-west-2.amazonaws.com
  aws_sdk_auth: true
  signature_version2: false
prefix: prod-cluster
```

## Security

This module implements security best practices:

- **S3 encryption at rest** using AES256
- **Public access blocking** on all S3 buckets
- **IAM least privilege** with bucket-scoped policies
- **IRSA authentication** eliminates need for long-lived credentials
- **Lifecycle policies** for automatic data retention management

## Multi-Cluster Architecture

The module supports a hub-and-spoke model:

- **Primary cluster**: Full read/write access (thanos-store can query and compact)
- **Remote clusters**: Write-only access (prometheus can push metrics)

All clusters write to the same bucket with different prefixes for isolation.

## Testing

```bash
# Lint and validate
make lint

# Run unit tests
make test-unit

# Run compliance tests
make test-compliance

# Run all tests
make all
```

## License

Copyright © 2025 KATN Solutions. All rights reserved.
