terraform {
  required_version = ">= 1.1.7, < 2.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.39.0, < 6.0.0"
    }

    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "4.8.0"
    }
  }
}
