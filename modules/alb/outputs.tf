# Outputs for the ALB module
output "alb_arn" {
  description = "The ARN of the ALB"
  value       = aws_lb.this.arn
}

output "alb_security_group_id" {
  description = "The security group ID of the ALB"
  value       = aws_security_group.this.id
}

output "alb_arn_suffix" {
  description = "The ARN suffix of the ALB"
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "The DNS name of the ALB"
  value       = aws_lb.this.dns_name
}

output "alb_target_group_arn" {
  description = "The ARN of the ALB target group"
  value       = aws_lb_target_group.this.arn
}

output "alb_target_group_arn_suffix" {
  description = "The ARN suffix of the ALB target group"
  value       = aws_lb_target_group.this.arn_suffix
}

output "alb_waf_arn" {
  description = "The ARN of the WAF Web ACL associated with the ALB"
  value       = one(aws_wafv2_web_acl.this[*].arn)
}

output "alb_access_logs_bucket_arn" {
  description = "The S3 bucket ARN for ALB access logs"
  value       = aws_s3_bucket.logs.arn
}

output "alb_module_info" {
  description = "Information about the ALB and associated resources"
  value = {
    alb_arn                     = aws_lb.this.arn
    alb_security_group_id       = aws_security_group.this.id
    alb_arn_suffix              = aws_lb.this.arn_suffix
    alb_dns_name                = aws_lb.this.dns_name
    alb_target_group_arn        = aws_lb_target_group.this.arn
    alb_target_group_arn_suffix = aws_lb_target_group.this.arn_suffix
    alb_waf_arn                 = one(aws_wafv2_web_acl.this[*].arn)
    alb_access_logs_bucket_arn  = aws_s3_bucket.logs.arn
  }
}
