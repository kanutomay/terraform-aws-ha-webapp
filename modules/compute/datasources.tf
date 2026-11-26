# Data source for the current AWS default tags
data "aws_default_tags" "current" {}

# Data source for the available EC2 instance types in the availability zones
data "aws_ec2_instance_type_offerings" "available" {
  for_each = toset(var.azs)
  filter {
    name   = "location"
    values = [each.key]
  }
  filter {
    name   = "instance-type"
    values = [var.instance_type]
  }
  location_type = "availability-zone"
}

# Data source for the selected EC2 instance type details
data "aws_ec2_instance_type" "selected" {
  instance_type = var.instance_type
}

# Data source for the latest Amazon Linux 2023 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Generate the IAM policy document for the compute instance assume role
data "aws_iam_policy_document" "compute_assume_role" {
  statement {
    effect = "Allow"

    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
