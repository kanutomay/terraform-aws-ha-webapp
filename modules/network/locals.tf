locals {
  # Local subnets assignment for the network module using offset to differentiate public and private subnets
  public_subnets = {
    for i, v in var.azs : v => cidrsubnet(var.vpc_cidr_block, 3, i + 0)
  }
  private_subnets = {
    for i, v in var.azs : v => cidrsubnet(var.vpc_cidr_block, 3, i + 4)
  }
}
