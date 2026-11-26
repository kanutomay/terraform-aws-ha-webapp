# Main Terraform configuration for the compute module

# IAM role and instance profile for compute instances
# The IAM role allows EC2 instances to assume the role defined by the policy document
# The instance profile associates the IAM role with the EC2 instances
resource "aws_iam_role" "this" {
  name               = "${var.project}-${var.environment}-compute-role"
  assume_role_policy = data.aws_iam_policy_document.compute_assume_role.json
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.project}-${var.environment}-compute-instance-profile"
  role = aws_iam_role.this.name
}

# EC2 instances Security Group
resource "aws_security_group" "this" {
  name        = "${var.project}-${var.environment}-compute-sg"
  description = "Security group for compute instances"
  vpc_id      = var.vpc_id

  tags = {
    Name = "${var.project}_${var.environment}_compute_sg"
  }
}

resource "aws_vpc_security_group_ingress_rule" "http_from_alb" {
  description                  = "Allow HTTP from ALB security group"
  security_group_id            = aws_security_group.this.id
  referenced_security_group_id = var.alb_security_group_id
  from_port                    = 80
  to_port                      = 80
  ip_protocol                  = "tcp"
}

resource "aws_vpc_security_group_egress_rule" "all_out" {
  security_group_id = aws_security_group.this.id
  from_port         = 0
  to_port           = 0
  ip_protocol       = "-1"
  cidr_ipv4         = "0.0.0.0/0"
}

# Launch template for EC2 instances
resource "aws_launch_template" "this" {
  name                   = "${var.project}-${var.environment}-compute-lt"
  image_id               = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.this.id]
  user_data              = filebase64("${path.module}/user-data.sh")

  # Lifecycle checks
  lifecycle {
    # Precondition to check if the instance type is available in the AZs
    precondition {
      condition = alltrue([
        for offering in data.aws_ec2_instance_type_offerings.available :
        contains(offering.instance_types, var.instance_type)
      ])
      error_message = "The instance type must be available in all specified availability zones."
    }

    # Precondition to check if the instance type is of x86_64 architecture
    precondition {
      condition     = contains(data.aws_ec2_instance_type.selected.supported_architectures, data.aws_ami.amazon_linux.architecture)
      error_message = "The instance type must be of ${data.aws_ami.amazon_linux.architecture} architecture."
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  # Block device mappings for the EC2 instances
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = 20
      volume_type = "gp3"
      encrypted   = true
    }
  }

  # Enable detailed monitoring for the EC2 instances
  monitoring {
    enabled = true
  }

  tags = {
    Name = "${var.project}_${var.environment}_compute_lt"
  }
}

# Auto Scaling Group for compute instances
## desired_capacity is managed automatically by Auto Scaling based on the scaling policies
resource "aws_autoscaling_group" "this" {
  name                      = "${var.project}-${var.environment}-compute-asg"
  max_size                  = var.asg_max_size
  min_size                  = var.asg_min_size
  vpc_zone_identifier       = var.subnets
  health_check_type         = "ELB"
  health_check_grace_period = 300 # Grace period for health checks in seconds
  target_group_arns         = [var.alb_target_group_arn]
  enabled_metrics           = ["GroupDesiredCapacity", "GroupInServiceInstances"]

  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version # Use the latest version of the launch template
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }

  tag {
    key                 = "Name"
    value               = "${var.project}_${var.environment}_web"
    propagate_at_launch = true
  }

  # Dynamic tags for AWS default tags - they don't propagate automatically, so we add them manually
  dynamic "tag" {
    for_each = data.aws_default_tags.current.tags
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }
}

# Auto Scaling policy for compute instances
resource "aws_autoscaling_policy" "this" {
  name                   = "${var.project}-${var.environment}-compute-scale-policy"
  autoscaling_group_name = aws_autoscaling_group.this.name
  policy_type            = "TargetTrackingScaling"
  target_tracking_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ASGAverageCPUUtilization"
    }
    target_value = 50.0
  }
}
