# Observability module main configuration

# SNS topic for observability notifications
resource "aws_sns_topic" "this" {
  name = "${var.project}-${var.environment}-observability-topic"
  tags = {
    Name = "${var.project}_${var.environment}_observability_topic"
  }
}

resource "aws_sns_topic_subscription" "this" {
  for_each  = toset(var.emails_list)
  topic_arn = aws_sns_topic.this.arn
  protocol  = "email"
  endpoint  = each.value
}

# Route 53 health check metrics and their alarm are in us-east-1. Create only if region is not us-east-1.
resource "aws_sns_topic" "route53" {
  count  = data.aws_region.current.region == "us-east-1" ? 0 : 1
  region = "us-east-1"
  name   = "${var.project}-${var.environment}-route53-observability-topic"
}

resource "aws_sns_topic_subscription" "route53" {
  for_each  = data.aws_region.current.region == "us-east-1" ? toset([]) : toset(var.emails_list)
  region    = "us-east-1"
  topic_arn = aws_sns_topic.route53[0].arn
  protocol  = "email"
  endpoint  = each.value
}

# VPC flow logs S3 bucket and related resources
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project}-${var.environment}-${data.aws_caller_identity.current.account_id}-flowlogs"
  force_destroy = var.environment == "dev"
  tags = {
    Name = "${var.project}_${var.environment}_flowlogs_bucket"
  }
}

# S3 bucket public access block for VPC flow logs bucket
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption configuration for VPC flow logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket lifecycle configuration
## For VPC flow logs transition to Standard-IA after 30 days, Glacier after 90 days and expire after 365 days
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id = "vpc-flow-logs"
    filter {}
    status = "Enabled"
    # Transition objects to Standard-IA after 30 days
    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }
    # Transition objects to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    # Delete objects after 365 days
    expiration {
      days = 365
    }
  }
}

# S3 bucket policy for VPC flow logs bucket
resource "aws_s3_bucket_policy" "vpc_flow_logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.s3_flow_logs_bucket_policy.json
}

# VPC flow log for the specified VPC
resource "aws_flow_log" "vpc" {
  depends_on           = [aws_s3_bucket_policy.vpc_flow_logs]
  log_destination      = aws_s3_bucket.logs.arn
  log_destination_type = "s3"
  traffic_type         = "ALL"
  vpc_id               = var.vpc_id
  destination_options {
    file_format        = "parquet"
    per_hour_partition = true
  }
}

# CloudWatch alarm for unhealthy ALB targets
resource "aws_cloudwatch_metric_alarm" "alb_targets" {
  alarm_name          = "${var.project}-${var.environment}-unhealthy-alb-targets-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "UnhealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Maximum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm for unhealthy ALB targets"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.alb_target_group_arn_suffix
  }
}

# CloudWatch alarm for fewer healthy targets than the ASG minimum
resource "aws_cloudwatch_metric_alarm" "low_healthy_targets" {
  alarm_name          = "${var.project}-${var.environment}-low-healthy-alb-targets-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthyHostCount"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Minimum"
  threshold           = var.asg_min_size
  treat_missing_data  = "breaching"
  alarm_description   = "Alarm when healthy ALB targets fall below the ASG minimum"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.alb_target_group_arn_suffix
  }
}

# CloudWatch alarm for ALB 5XX errors
resource "aws_cloudwatch_metric_alarm" "alb_5xx_errors" {
  alarm_name          = "${var.project}-${var.environment}-alb-5xx-errors-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  unit                = "Count"
  threshold           = 10
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm for ALB 5XX errors"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
  }
}

# CloudWatch alarm for application-generated 5XX errors
resource "aws_cloudwatch_metric_alarm" "target_5xx_errors" {
  alarm_name          = "${var.project}-${var.environment}-target-5xx-errors-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "HTTPCode_Target_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  treat_missing_data  = "notBreaching"
  alarm_description   = "Alarm when an application target returns a 5XX response"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    LoadBalancer = var.alb_arn_suffix
    TargetGroup  = var.alb_target_group_arn_suffix
  }
}

# Check the public ALB endpoint from Route 53 health checkers
resource "aws_route53_health_check" "alb" {
  fqdn              = var.alb_dns_name
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  request_interval  = 30
  failure_threshold = 3

  tags = {
    Name = "${var.project}_${var.environment}_alb_external_health"
  }
}

resource "aws_cloudwatch_metric_alarm" "external_availability" {
  region              = "us-east-1"
  alarm_name          = "${var.project}-${var.environment}-external-availability-alarm"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "HealthCheckStatus"
  namespace           = "AWS/Route53"
  period              = 60
  statistic           = "Minimum"
  threshold           = 1
  treat_missing_data  = "breaching"
  alarm_description   = "Alarm when the public ALB health check fails or stops reporting"
  alarm_actions       = [data.aws_region.current.region == "us-east-1" ? aws_sns_topic.this.arn : aws_sns_topic.route53[0].arn]
  ok_actions          = [data.aws_region.current.region == "us-east-1" ? aws_sns_topic.this.arn : aws_sns_topic.route53[0].arn]
  dimensions = {
    HealthCheckId = aws_route53_health_check.alb.id
  }
}

# CloudWatch alarm for high CPU utilization in the ASG
resource "aws_cloudwatch_metric_alarm" "high_cpu" {
  alarm_name          = "${var.project}-${var.environment}-high-cpu-alarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60 # If using EC2 default monitoring change to 300.
  statistic           = "Average"
  threshold           = 80
  alarm_description   = "Alarm for high CPU utilization - ASG scaling issues"
  alarm_actions       = [aws_sns_topic.this.arn]
  ok_actions          = [aws_sns_topic.this.arn]
  dimensions = {
    AutoScalingGroupName = var.asg_name
  }
}

# CloudWatch dashboard showing the observability alarm states
resource "aws_cloudwatch_dashboard" "this" {
  dashboard_name = "${var.project}-${var.environment}-observability-dashboard"
  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "alarm"
        x      = 0
        y      = 0
        width  = 24
        height = 6
        properties = {
          title = "Application alarms"
          alarms = [
            aws_cloudwatch_metric_alarm.alb_targets.arn,
            aws_cloudwatch_metric_alarm.low_healthy_targets.arn,
            aws_cloudwatch_metric_alarm.alb_5xx_errors.arn,
            aws_cloudwatch_metric_alarm.target_5xx_errors.arn,
            aws_cloudwatch_metric_alarm.external_availability.arn,
            aws_cloudwatch_metric_alarm.high_cpu.arn
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "ALB requests"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.region
          period  = 60
          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              var.alb_arn_suffix,
              { stat = "Sum", label = "Requests" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title   = "Healthy ALB targets"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.region
          period  = 60
          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "LoadBalancer",
              var.alb_arn_suffix,
              "TargetGroup",
              var.alb_target_group_arn_suffix,
              { stat = "Minimum", label = "Healthy targets" }
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title   = "ASG desired and in-service capacity"
          view    = "timeSeries"
          stacked = false
          region  = data.aws_region.current.region
          period  = 60
          metrics = [
            ["AWS/AutoScaling", "GroupDesiredCapacity", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "Desired" }],
            ["AWS/AutoScaling", "GroupInServiceInstances", "AutoScalingGroupName", var.asg_name, { stat = "Average", label = "In service" }]
          ]
        }
      }
    ]
  })
}
