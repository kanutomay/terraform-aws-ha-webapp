# Main Terraform configuration for the ALB module
# ALB Security group
resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-alb-sg"
  description = "Security group for the ALB"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}_${var.environment}_alb_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_in" {
  security_group_id = aws_security_group.this.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = "0.0.0.0/0"
}

resource "aws_vpc_security_group_egress_rule" "http_to_vpc" {
  security_group_id = aws_security_group.this.id
  from_port         = 80
  to_port           = 80
  ip_protocol       = "tcp"
  cidr_ipv4         = var.vpc_cidr_block
}


# ALB access logs S3 bucket
resource "aws_s3_bucket" "logs" {
  bucket        = "${var.project}-${var.environment}-${data.aws_caller_identity.current.account_id}-alb-access-logs"
  force_destroy = var.environment == "dev"
  tags = {
    Name = "${var.project}_${var.environment}_alb_access_logs_bucket"
  }
}

# S3 bucket public access block for ALB access logs bucket
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket                  = aws_s3_bucket.logs.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 bucket server-side encryption configuration for ALB access logs bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 bucket lifecycle configuration
## For ALB access logs transition to Standard-IA after 30 days, Glacier after 90 days and expire after 365 days
resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id
  rule {
    id = "alb-access-logs"
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

# S3 bucket policy for ALB access logs bucket
resource "aws_s3_bucket_policy" "alb_access_logs" {
  bucket = aws_s3_bucket.logs.id
  policy = data.aws_iam_policy_document.s3_alb_access_logs_bucket_policy.json
}

# Application Load Balancer (ALB) resource definition
resource "aws_lb" "this" {
  depends_on                 = [aws_s3_bucket_policy.alb_access_logs] # Ensure the ALB is created after the S3 bucket policy for access logs is in place
  name                       = "${var.project}-${var.environment}-alb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.this.id]
  subnets                    = var.subnets
  enable_deletion_protection = false
  drop_invalid_header_fields = true
  access_logs {
    bucket  = aws_s3_bucket.logs.id
    enabled = true
  }

  tags = {
    Name = "${var.project}_${var.environment}_alb"
  }
}

# Target group for the ALB to route traffic to the backend instances
resource "aws_lb_target_group" "this" {
  name                 = "${var.project}-${var.environment}-alb-tg"
  port                 = 80
  protocol             = "HTTP"
  vpc_id               = var.vpc_id
  deregistration_delay = 30

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
    matcher             = "200"
  }

  tags = {
    Name = "${var.project}_${var.environment}_alb_tg"
  }
}

# Listener for the ALB to forward HTTP traffic to the target group
resource "aws_lb_listener" "this" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }
}

# WAF Web ACL for the ALB
resource "aws_wafv2_web_acl" "this" {
  count       = var.enable_waf ? 1 : 0 # Only create the WAF Web ACL if WAF is enabled
  name        = "${var.project}-${var.environment}-alb-waf"
  scope       = "REGIONAL"
  description = "WAF Web ACL for the ALB"

  default_action {
    allow {}
  }

  rule {
    name     = "aws-common-rule-set"
    priority = 1

    override_action {
      none {}
    }

    statement {
      managed_rule_group_statement {
        name        = "AWSManagedRulesCommonRuleSet"
        vendor_name = "AWS"
      }
    }

    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "${var.project}-${var.environment}-alb-waf-common-rule-set"
      sampled_requests_enabled   = true
    }

  }

  tags = {
    Name = "${var.project}_${var.environment}_alb_waf"
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "${var.project}-${var.environment}-alb-waf"
    sampled_requests_enabled   = true
  }
}

# Association of the WAF Web ACL with the ALB
resource "aws_wafv2_web_acl_association" "this" {
  count        = var.enable_waf ? 1 : 0 # Only create the association if WAF is enabled
  resource_arn = aws_lb.this.arn
  web_acl_arn  = aws_wafv2_web_acl.this[count.index].arn
}
