aws_region = "us-east-1"

vpc_name = "cmtr-znhvv6bs-01-vpc"
vpc_cidr = "10.10.0.0/16"

# Keys (a/b/c) become part of the subnet Name tag via locals in vpc.tf
public_subnets = {
  a = { az = "us-east-1a", cidr = "10.10.1.0/24" }
  b = { az = "us-east-1b", cidr = "10.10.3.0/24" }
  c = { az = "us-east-1c", cidr = "10.10.5.0/24" }
}

igw_name = "cmtr-znhvv6bs-01-igw"
rt_name  = "cmtr-znhvv6bs-01-rt"
