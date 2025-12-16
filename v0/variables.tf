variable "organization" {
  type        = string
  description = "Organization name for resource naming"
}

variable "cluster_name" {
  type        = string
  description = "Name of the Kubernetes cluster"
}

variable "environment" {
  type        = string
  description = "Environment (dev/staging/prod)"
}

variable "lifecycle_retention_days" {
  type        = number
  description = "S3 lifecycle retention in days"
  default     = 5
}

variable "oidc_provider_arn" {
  type        = string
  description = "ARN of the EKS OIDC provider"
}

variable "oidc_provider_url" {
  type        = string
  description = "URL of the EKS OIDC provider (without https://)"
}

variable "service_account_namespace" {
  type        = string
  description = "Kubernetes namespace for Thanos service account"
  default     = "monitoring"
}

variable "service_account_name" {
  type        = string
  description = "Kubernetes service account name for Thanos"
  default     = "thanos-store"
}

variable "additional_service_accounts" {
  type = list(object({
    namespace = string
    name      = string
  }))
  description = "Additional service accounts for the primary IAM role"
  default     = []
}

variable "additional_writer_roles" {
  type = list(object({
    name                      = string
    oidc_provider_arn         = string
    oidc_provider_url         = string
    service_account_namespace = string
    service_account_name      = string
  }))
  description = "Additional writer roles for multi-cluster setup"
  default     = []
}

variable "enable_encryption" {
  type        = bool
  description = "Enable S3 bucket encryption"
  default     = true
}

variable "tags" {
  type        = map(string)
  description = "Additional tags for resources"
  default     = {}
}

variable "enable_dns" {
  type        = bool
  description = "Enable DNS record creation"
  default     = false
}

variable "dns_hostname" {
  type        = string
  description = "DNS hostname for Thanos (required if enable_dns=true)"
  default     = ""
}

variable "dns_provider" {
  type        = string
  description = "DNS provider to use (cloudflare or route53)"
  default     = "cloudflare"
  validation {
    condition     = contains(["cloudflare", "route53"], var.dns_provider)
    error_message = "dns_provider must be either 'cloudflare' or 'route53'"
  }
}

variable "dns_zone_id" {
  type        = string
  description = "DNS Zone ID (Cloudflare Zone ID or Route53 Hosted Zone ID)"
  default     = ""
}
