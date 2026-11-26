# Outputs for the network module including public and private subnets and VPC ID
output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.this.id
}
output "public_subnet_ids" {
  description = "IDs of public subnets"
  value       = [for s in aws_subnet.public : s.id]
}
output "private_subnet_ids" {
  description = "IDs of private subnets"
  value       = [for s in aws_subnet.private : s.id]
}
output "selected_availability_zones" {
  description = "Availability zones chosen for the subnets (public azs = private azs)"
  value       = [for s in aws_subnet.public : s.availability_zone]
}
output "vpc_extended" {
  description = "Extended information for the VPC"
  value = {
    arn        = aws_vpc.this.arn,
    id         = aws_vpc.this.id,
    cidr_block = aws_vpc.this.cidr_block,
    region     = aws_vpc.this.region
  }
}
output "public_subnets_extended" {
  description = "Extended information for public subnets"
  value = { for k, v in aws_subnet.public : k => {
    arn        = v.arn,
    id         = v.id,
    az         = v.availability_zone,
    cidr_block = v.cidr_block
    }
  }
}
output "private_subnets_extended" {
  description = "Extended information for private subnets"
  value = { for k, v in aws_subnet.private : k => {
    arn        = v.arn,
    id         = v.id,
    az         = v.availability_zone,
    cidr_block = v.cidr_block
    }
  }
}
