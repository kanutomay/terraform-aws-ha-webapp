# Outputs for the compute module
output "asg_name" {
  description = "The name of the Auto Scaling Group for compute instances"
  value       = aws_autoscaling_group.this.name
}
output "asg_min_size" {
  description = "The minimum number of instances to maintain by ASG"
  value       = aws_autoscaling_group.this.min_size
}
output "launch_template_id" {
  description = "The ID of the launch template for compute instances"
  value       = aws_launch_template.this.id
}

output "security_group_id" {
  description = "The ID of the security group for compute instances"
  value       = aws_security_group.this.id
}

output "iam_instance_profile" {
  description = "The name of the IAM instance profile for compute instances"
  value       = aws_iam_instance_profile.this.name
}

output "iam_role" {
  description = "The name of the IAM role for compute instances"
  value       = aws_iam_role.this.name
}
output "compute_module_info" {
  description = "Information about the compute module"
  value = {
    asg_name             = aws_autoscaling_group.this.name
    asg_min_size         = aws_autoscaling_group.this.min_size
    launch_template_id   = aws_launch_template.this.id
    security_group_id    = aws_security_group.this.id
    iam_instance_profile = aws_iam_instance_profile.this.name
    iam_role             = aws_iam_role.this.name
  }
}
