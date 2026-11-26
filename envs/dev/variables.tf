# Terraform variables definition for the dev environment
variable "project" {
  description = "The project name"
  type        = string
}

variable "environment" {
  description = "The environment name"
  type        = string
}

variable "vpc_cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "region" {
  description = "The AWS region"
  type        = string
}

variable "azs" {
  description = "The availability zones"
  type        = list(string)
}

variable "enable_waf" {
  description = "Flag to enable WAF"
  type        = bool
  default     = null
}

variable "instance_type" {
  description = "The instance type for the compute module"
  type        = string
}

variable "asg_min_size" {
  description = "The minimum size of the auto scaling group"
  type        = number
}

variable "asg_max_size" {
  description = "The maximum size of the auto scaling group"
  type        = number
}

variable "emails_list" {
  description = "The list of email addresses for notifications"
  type        = list(string)
}
