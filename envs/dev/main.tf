module "network" {
  source = "../../modules/network"
  # Pass project name, environment, VPC CIDR block and availability zones to the network module
  project        = var.project
  environment    = var.environment
  vpc_cidr_block = var.vpc_cidr_block
  azs            = var.azs
}

module "alb" {
  source         = "../../modules/alb"
  project        = var.project
  environment    = var.environment
  vpc_id         = module.network.vpc_id
  vpc_cidr_block = module.network.vpc_extended.cidr_block
  subnets        = module.network.public_subnet_ids
  enable_waf     = local.enable_waf # Enable WAF for non-dev environments unless explicitly overridden
}

module "compute" {
  source                = "../../modules/compute"
  project               = var.project
  environment           = var.environment
  instance_type         = var.instance_type
  asg_min_size          = var.asg_min_size
  asg_max_size          = var.asg_max_size
  vpc_id                = module.network.vpc_id
  subnets               = module.network.private_subnet_ids
  azs                   = module.network.selected_availability_zones
  alb_security_group_id = module.alb.alb_security_group_id
  alb_target_group_arn  = module.alb.alb_target_group_arn
}

module "observability" {
  source                      = "../../modules/observability"
  project                     = var.project
  environment                 = var.environment
  emails_list                 = var.emails_list
  vpc_id                      = module.network.vpc_id
  asg_name                    = module.compute.asg_name
  asg_min_size                = module.compute.asg_min_size
  alb_dns_name                = module.alb.alb_dns_name
  alb_arn_suffix              = module.alb.alb_arn_suffix
  alb_target_group_arn_suffix = module.alb.alb_target_group_arn_suffix
}
