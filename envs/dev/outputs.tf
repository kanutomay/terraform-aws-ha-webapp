# envs/dev/outputs.tf

output "deployment_input_info" {
  description = "Information about the deployment"
  value = {
    project        = var.project
    environment    = var.environment
    vpc_cidr_block = var.vpc_cidr_block
    region         = var.region
    azs            = var.azs
    instance_type  = var.instance_type
    asg_min_size   = var.asg_min_size
    asg_max_size   = var.asg_max_size
    enable_waf     = local.enable_waf
  }
}
output "vpc_info" {
  description = "Extended information for the VPC"
  value       = module.network.vpc_extended
}
output "public_subnets_info" {
  description = "Public subnets keyed by AZ"
  value       = module.network.public_subnets_extended
}
output "private_subnets_info" {
  description = "Private subnets keyed by AZ"
  value       = module.network.private_subnets_extended
}
output "alb_info" {
  description = "Information about the ALB and associated resources"
  value       = module.alb.alb_module_info
}
output "compute_info" {
  description = "Information about the compute module"
  value       = module.compute.compute_module_info
}
output "observability_info" {
  description = "Information about the observability module"
  value       = module.observability.observability_module_info
}
