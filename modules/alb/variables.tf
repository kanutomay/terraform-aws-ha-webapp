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
variable "vpc_id" {
  description = "The ID of the VPC where the ALB will be deployed"
  type        = string
}
variable "vpc_cidr_block" {
  description = "The CIDR block of the VPC where the ALB will be deployed"
  type        = string
}
variable "subnets" {
  description = "The subnets where the ALB will be deployed"
  type        = list(string)
}
variable "enable_waf" {
  description = "Enable WAF for the ALB"
  type        = bool
  default     = false
  nullable    = false # The variable cannot be null
}
