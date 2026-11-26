# Terraform variables definition
variable "project" {
  description = "The project name"
  type        = string
}
variable "environment" {
  description = "The environment name (e.g., dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be either 'dev', 'staging', or 'prod'."
  }
}
variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
  validation {
    # Subnets use smaller CIDR blocks (3 newbits), so we limit the VPC CIDR block to a prefix between /16 and /24 to comply with design constraints
    condition = (
      can(cidrnetmask(var.vpc_cidr_block)) &&
      can(regex("^.*/(1[6-9]|2[0-4])$", var.vpc_cidr_block))
    )
    error_message = "The VPC CIDR block must be a valid IPv4 CIDR with a prefix between /16 and /24."
  }
}
variable "azs" {
  description = "The list of availability zones for the environment"
  type        = list(string)
  validation {
    condition = (
      length(var.azs) >= 2 &&
      length(var.azs) <= 4 &&
      length(distinct(var.azs)) == length(var.azs)
    )
    error_message = "Specify between 2 and 4 unique availability zones."
  }
  validation {
    condition     = alltrue([for az in var.azs : contains(data.aws_availability_zones.available.names, az)])
    error_message = "All availability zones must be valid and available."
  }
}
