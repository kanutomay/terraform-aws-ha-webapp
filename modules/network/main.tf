# This module will create the following resources:
# - VPC
# - Public subnets (one per availability zone)
# - Private subnets (one per availability zone)
# - Internet gateway for the VPC
# - Regional NAT gateway for private subnets with EIP automatic allocation (auto mode - no need for EIP definition)
# - S3 endpoint for the VPC
# - Route tables for public and private subnets

resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "${var.project}_${var.environment}"
  }
}

# Public subnets for the VPC (one per availability zone)
resource "aws_subnet" "public" {
  for_each                = local.public_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  # Default tags will be applied by the provider
  tags = {
    Name = "${var.project}_${var.environment}_public_${each.key}"
  }
}

# Private subnets for the VPC (one per availability zone)
resource "aws_subnet" "private" {
  for_each                = local.private_subnets
  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value
  availability_zone       = each.key
  map_public_ip_on_launch = false

  # Default tags will be applied by the provider
  tags = {
    Name = "${var.project}_${var.environment}_private_${each.key}"
  }
}

# Internet gateway for the VPC
resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = {
    Name = "${var.project}_${var.environment}_igw"
  }
}

# Regional NAT gateway with auto mode (EIP) for the VPC
# This NAT gateway will allow private subnets to access the internet while keeping them private
resource "aws_nat_gateway" "this" {
  depends_on        = [aws_internet_gateway.this]
  vpc_id            = aws_vpc.this.id
  availability_mode = "regional"

  tags = {
    Name = "${var.project}_${var.environment}_nat"
  }
}

# S3 VPC endpoint for the VPC
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.this.id
  service_name      = "com.amazonaws.${data.aws_region.current.region}.s3"
  vpc_endpoint_type = "Gateway"

  tags = {
    Name = "${var.project}_${var.environment}_s3_gw_endpoint"
  }
}

# Define route table for public subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.this.id
  }

  tags = {
    Name = "${var.project}_${var.environment}_public_rt"
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

# Define route table for private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.this.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.this.id
  }

  tags = {
    Name = "${var.project}_${var.environment}_private_rt"
  }
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

# Associate the S3 VPC endpoint with the private route table
resource "aws_vpc_endpoint_route_table_association" "s3_private" {
  vpc_endpoint_id = aws_vpc_endpoint.s3.id
  route_table_id  = aws_route_table.private.id
}
