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
variable "instance_type" {
  description = "The instance type for the EC2 instances"
  type        = string
}
variable "asg_min_size" {
  description = "The minimum size of the Auto Scaling group"
  type        = number
  validation {
    condition     = floor(var.asg_min_size) == var.asg_min_size
    error_message = "The minimum size of the Auto Scaling group must be an integer."
  }
  validation {
    condition     = var.asg_min_size >= 2
    error_message = "The minimum size of the Auto Scaling group must be at least 2 for HA."
  }
}
variable "asg_max_size" {
  description = "The maximum size of the Auto Scaling group"
  type        = number
  validation {
    condition     = floor(var.asg_max_size) == var.asg_max_size
    error_message = "The maximum size of the Auto Scaling group must be an integer."
  }
  validation {
    condition     = var.asg_max_size >= var.asg_min_size
    error_message = "The maximum size of the Auto Scaling group must be greater than or equal to the minimum size."
  }
}
variable "vpc_id" {
  description = "The ID of the VPC where the EC2 instances will be deployed"
  type        = string
}
variable "subnets" {
  description = "The subnets where the EC2 instances will be deployed"
  type        = list(string)
}
variable "azs" {
  description = "The availability zones for the EC2 instances"
  type        = list(string)
}
variable "alb_security_group_id" {
  description = "The security group ID of the ALB"
  type        = string
}
variable "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  type        = string
}
