# Provider configuration for frontend infrastructure
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# Main provider - uses region from variables
provider "aws" {
  region = var.aws_region

  default_tags {
    tags = var.common_tags
  }
}

# Additional provider for us-east-1 (required for CloudFront WAF)
provider "aws" {
  alias  = "east"
  region = "us-east-1"

  default_tags {
    tags = var.common_tags
  }
}
