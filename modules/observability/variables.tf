# Variables for observability module
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
variable "emails_list" {
  description = "List of email addresses for SNS topic subscriptions"
  type        = list(string)
  validation {
    condition     = length(var.emails_list) > 0
    error_message = "The emails_list must contain at least one email address."
  }
  validation {
    condition     = alltrue([for email in var.emails_list : can(regex(".+@.+\\..+", email))])
    error_message = "All entries in emails_list must be valid email addresses."
  }
  validation {
    condition     = alltrue([for email in var.emails_list : email != "example@example.com"])
    error_message = "The emails_list must not contain the placeholder email 'example@example.com'."
  }
}
variable "vpc_id" {
  description = "The ID of the VPC for which to create flow logs"
  type        = string
}
variable "asg_name" {
  description = "The name of the Auto Scaling Group"
  type        = string
}
variable "asg_min_size" {
  description = "Minimum number of healthy ALB targets"
  type        = number
}
variable "alb_dns_name" {
  description = "Public DNS name of the ALB to monitor externally"
  type        = string
}
variable "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  type        = string
}
variable "alb_target_group_arn_suffix" {
  description = "The ARN suffix of the ALB target group"
  type        = string
}
