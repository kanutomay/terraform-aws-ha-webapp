# Data sources for the network module including current region and available availability zones
data "aws_region" "current" {}

data "aws_availability_zones" "available" {
  state = "available"
}
