# Provider configuration.
# Region is driven by variable so the config is not hardcoded to a specific environment.
provider "aws" {
  region = var.aws_region
}

# Common tags applied to all resources.
# Using locals ensures a single source of truth — update here, propagates everywhere.
locals {
  common_tags = {
    Project = "epam-tf-lab"
    ID      = var.project_id
  }
}

# Reference the pre-existing VPC created by the course platform via CloudFormation.
# We use a data source because Terraform does not own this resource.
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["${var.project_id}-vpc"]
  }
}

# Discover public subnets within the VPC.
# Filtered by map-public-ip-on-launch=true to ensure EC2 instances get a public IP.
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.main.id]
  }

  filter {
    name   = "map-public-ip-on-launch"
    values = ["true"]
  }
}

# Reference the pre-existing security group created by the course platform.
# This SG allows inbound SSH (port 22) access to EC2 instances.
data "aws_security_group" "ssh" {
  filter {
    name   = "tag:Name"
    values = [var.aws_security_group_name]
  }
}
