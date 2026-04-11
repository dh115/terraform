# ── Region ────────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
}

# ── VPC ───────────────────────────────────────────────────────────────────────

variable "vpc_name" {
  description = "Name tag for the VPC."
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC (e.g. 10.10.0.0/16)."
  type        = string
}

# ── Subnets ───────────────────────────────────────────────────────────────────

# https://developer.hashicorp.com/terraform/language/expressions/types#map

#public_subnets = {
#  a = { az = "us-east-1a", cidr = "10.10.1.0/24" }
#  b = { az = "us-east-1b", cidr = "10.10.3.0/24" }
#  c = { az = "us-east-1c", cidr = "10.10.5.0/24" }
#}

# Each subnet is represented as an object so a single variable drives the
# for_each loop — avoids repeating three near-identical resource blocks.
variable "public_subnets" {
  description = "Map of public subnets to create. Key is a short suffix (a/b/c), value holds AZ and CIDR."
  type = map(object({
    az   = string
    cidr = string
  }))
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

variable "igw_name" {
  description = "Name tag for the Internet Gateway."
  type        = string
}

# ── Route Table ───────────────────────────────────────────────────────────────

variable "rt_name" {
  description = "Name tag for the public route table."
  type        = string
}
