terraform {
  # Specify the required Terraform version
  required_version = ">= 1.11"

  # Specify the required providers and their versions
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
