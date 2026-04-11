# ── Locals ────────────────────────────────────────────────────────────────────

locals {
  # Build the full subnet name from the base prefix in tfvars + the map key.
  # e.g. key "a" → "cmtr-znhvv6bs-01-subnet-public-a"
  # This keeps the name logic in one place and avoids any hardcoding in resources.
  subnet_name_prefix = "cmtr-znhvv6bs-01-subnet-public"
}

# ── VPC ───────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr

  # enable_dns_hostnames lets EC2 instances get public DNS names — useful for
  # services that will later sit in these public subnets.
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = var.vpc_name
  }
}

# ── Public Subnets ────────────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  # One subnet resource block handles all three subnets via for_each.
  # Terraform creates a separate instance for each key (a, b, c).
  # https://developer.hashicorp.com/terraform/language/meta-arguments/for_each

  for_each = var.public_subnets

  #public_subnets = {
  #  a = { az = "us-east-1a", cidr = "10.10.1.0/24" }
  #  b = { az = "us-east-1b", cidr = "10.10.3.0/24" }
  #  c = { az = "us-east-1c", cidr = "10.10.5.0/24" }
  #}

  #each.key → a/b/c
  #each.value.az/each.value.cidr

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value.cidr
  availability_zone = each.value.az

  # Auto-assign a public IP so instances launched here can reach the internet
  # without manual Elastic IP assignment.
  map_public_ip_on_launch = true

  tags = {
    # "${local.subnet_name_prefix}-${each.key}" → e.g. "cmtr-znhvv6bs-01-subnet-public-a"
    Name = "${local.subnet_name_prefix}-${each.key}"
  }
}

# ── Internet Gateway ──────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  # Attaching the IGW to the VPC at creation time (vs. a separate
  # aws_internet_gateway_attachment) is the standard, simpler approach.
  vpc_id = aws_vpc.main.id

  tags = {
    Name = var.igw_name
  }
}

# ── Route Table ───────────────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  # Default route: send all non-local traffic (0.0.0.0/0) out through the IGW.
  # This is what makes subnets "public".
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = var.rt_name
  }
}

# ── Route Table Associations ──────────────────────────────────────────────────

resource "aws_route_table_association" "public" {
  # Associate every public subnet with the public route table.
  # for_each mirrors the subnet map so keys stay consistent (a, b, c).
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}
