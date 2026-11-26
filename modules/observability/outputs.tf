# Outputs for observability module

output "sns_topic_arn" {
  description = "ARN of the SNS topic for observability notifications"
  value       = aws_sns_topic.this.arn
}

output "vpc_flow_logs_bucket_arn" {
  description = "ARN of the S3 bucket for VPC flow logs"
  value       = aws_s3_bucket.logs.arn
}

output "vpc_flow_log_id" {
  description = "ID of the VPC flow log"
  value       = aws_flow_log.vpc.id
}

output "cloudwatch_dashboard_name" {
  description = "Name of the CloudWatch dashboard for observability alarms"
  value       = aws_cloudwatch_dashboard.this.dashboard_name
}

output "cloudwatch_dashboard_url" {
  description = "URL of the CloudWatch dashboard for observability alarms"
  value       = "https://${data.aws_region.current.region}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards:name=${aws_cloudwatch_dashboard.this.dashboard_name}"
}

output "observability_module_info" {
  description = "Information about the observability module"
  value = {
    sns_topic_arn             = aws_sns_topic.this.arn
    vpc_flow_logs_bucket_arn  = aws_s3_bucket.logs.arn
    vpc_flow_log_id           = aws_flow_log.vpc.id
    cloudwatch_dashboard_name = aws_cloudwatch_dashboard.this.dashboard_name
    cloudwatch_dashboard_url  = "https://${data.aws_region.current.region}.console.aws.amazon.com/cloudwatch/home?region=${data.aws_region.current.region}#dashboards:name=${aws_cloudwatch_dashboard.this.dashboard_name}"
  }
}
