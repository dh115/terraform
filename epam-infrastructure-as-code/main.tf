terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ─── VPC ──────────────────────────────────────────────────────
# Your isolated network in AWS. Everything lives inside this.
# Without a VPC, resources float in the default AWS VPC which
# you don't control and is shared — bad practice.
# https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true   # lets resources resolve domain names
  enable_dns_hostnames = true   # gives EC2 instances DNS hostnames

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# ─── INTERNET GATEWAY ─────────────────────────────────────────
# Connects your VPC to the internet.
# Without this, your VPC is completely isolated — no in or out traffic.
# Think of it as the modem/router for your entire VPC.
# https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html

# IGW must be attached to VPC. No other action is available for IGW. 

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# ─── PUBLIC SUBNETS ───────────────────────────────────────────
# Subnets are segments of your VPC CIDR, each locked to one AZ.
# We need TWO subnets in TWO different AZs because:
#   1. ALB is an AWS requirement — it must span at least 2 AZs
#   2. If one AZ goes down, traffic still flows through the other
#
# "Public" means resources here can have public IPs and reach the internet
# via the route table we define below.

# https://docs.aws.amazon.com/vpc/latest/userguide/configure-subnets.html

# We skipped private subnets to keep things simple for now, but in a real setup you would always put EC2 instances in private subnets.


resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"       # 256 IPs in AZ-a
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true                 # EC2s here get a public IP automatically

  tags = {
    Name = "${var.project_name}-public-a"
    Tier = "public"
  }
}

resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"       # different range, same VPC
  availability_zone       = "${var.aws_region}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-b"
    Tier = "public"
  }
}

# ─── ROUTE TABLE ──────────────────────────────────────────────
# Rules that control where network traffic is directed.
# This one says: send all outbound traffic (0.0.0.0/0) to the IGW.
# Without this route, instances have public IPs but can't reach the internet
# and the internet can't reach them.

#https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Route_Tables.html

# Here we associate the route table with the internet gateway.

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-rt-public"
  }
}

# Attach the route table to BOTH subnets.
# Each subnet needs its own association — one association per subnet.

# And here we associate our subnets with the routing table.

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# ─── SECURITY GROUP: ALB ──────────────────────────────────────
# The ALB is the only thing exposed to the internet.
# It accepts HTTP (port 80) from anyone and forwards to EC2.
# We keep ALB and EC2 security groups SEPARATE so we can control
# exactly what talks to what.

# https://docs.aws.amazon.com/vpc/latest/userguide/vpc-security-groups.html

# ─── SECURITY GROUPS vs NACLs ─────────────────────────────────
#
# SECURITY GROUPS                    NACLs
# --------------                     -----
# Attached to instance/ENI           Attached to subnet
# Stateful (return traffic auto      Stateless (must explicitly allow
#   allowed, no outbound rule          both inbound AND outbound)
#   needed for responses)
# Allow rules only                   Allow AND deny rules
# All rules evaluated together       Rules evaluated in order by number
#                                      (first match wins)
#
# Traffic flow:
#   Internet → NACL (subnet level) → Security Group (instance level) → EC2
#
# In practice:
#   Security groups handle most access control (easier, stateful).
#   NACLs used for broad subnet-level blocks e.g. banning an IP range.
#   Default NACL allows all traffic, so it is transparent unless configured.

resource "aws_security_group" "alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Allow HTTP from internet"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound to reach EC2. Without this the ALB wouldn not be able to forward the connections to EC2 instances"
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # all protocols
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-alb-sg"
  }
}

# ─── SECURITY GROUP: EC2 ──────────────────────────────────────
# EC2 instances should NOT be reachable directly from the internet.
# HTTP is only allowed FROM the ALB security group — not from any IP.
# This is called "security group chaining" and is a best practice.
#
# How it works: instead of cidr_blocks, we use security_groups = [alb sg id]
# meaning "only allow traffic that came through the ALB security group."

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "Allow SSH and HTTP from ALB only"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "SSH - for direct terminal access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # restrict to your IP in production
  }

  ingress {
    description     = "HTTP - only from ALB, not the open internet"
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id] # Allow traffic from any resource that has this security group attached
  }

  egress {
    description = "This allows the EC2 instance itself to initiate outbound connections (updates, connection to an RDS DB)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg"
  }
}

# ─── SSH KEY PAIR ─────────────────────────────────────────────
# EC2 uses key pairs instead of passwords. You keep the private key,
# AWS stores the public key. When you SSH, your private key proves your identity.
#
# BEFORE running terraform apply, generate your key pair locally:
#   ssh-keygen -t ed25519 -f ~/.ssh/myapp-key
#
# This creates:
#   ~/.ssh/myapp-key      ← private key (never share this)
#   ~/.ssh/myapp-key.pub  ← public key (this goes to AWS)
#
# The file() function reads the .pub file content and sends it to AWS.

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = file(var.public_key_path)
}

# ─── EC2 INSTANCES ────────────────────────────────────────────
# count = 2 creates two identical instances.
# count.index is 0 for the first, 1 for the second — used for naming
# and for placing each instance in a different subnet.
#
# element([subnet_a, subnet_b], count.index) alternates subnets:
#   instance 0 → public_a
#   instance 1 → public_b
# This spreads instances across AZs for availability.

# https://docs.aws.amazon.com/ec2/
# https://developer.hashicorp.com/terraform/language/functions/element

# Use the built-in index syntax list[index] in most cases. Use this function only for the special additional "wrap-around" behavior described below.
# The wrapping behavior is where `element` becomes useful. If you had 4 instances but only 2 subnets:

# count.index = 0 → index 0 → public_a
# count.index = 1 → index 1 → public_b
# count.index = 2 → index 2 → wraps back to 0 → public_a
# count.index = 3 → index 3 → wraps back to 1 → public_b

# So instances spread evenly across subnets no matter how many you create. This is why element is preferred over direct indexing like [count.index] — direct indexing would crash if count.index exceeds the list length:

resource "aws_instance" "server" {
  count = var.instance_count

  ami                    = var.instance_ami
  instance_type          = var.instance_type
  subnet_id              = element([aws_subnet.public_a.id, aws_subnet.public_b.id], count.index)
  vpc_security_group_ids = [aws_security_group.ec2.id]
  key_name               = aws_key_pair.main.key_name

  user_data = <<-EOF
    #!/bin/bash
    yum update -y
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    # each instance identifies itself so you can see ALB is load balancing
    echo "<h1>Hello from Server ${count.index}</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name = "${var.project_name}-server-${count.index}"
  }
}

# ─── TARGET GROUP ─────────────────────────────────────────────
# The target group is the list of EC2s the ALB sends traffic to.
# The ALB health checks each target on the path "/" every 30 seconds.
# If an instance returns anything other than 200, it gets marked
# unhealthy and the ALB stops sending it traffic until it recovers.

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-target-groups.html

# Target Group — the group itself. Just a container with rules about HOW to send traffic and HOW to check if targets are healthy. It has no actual servers in it yet.

resource "aws_lb_target_group" "app" {
  name     = "${var.project_name}-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }

  tags = {
    Name = "${var.project_name}-tg"
  }
}

# Registers each EC2 into the target group.
# count.index matches the EC2 instances above, so server[0] → attachment[0] etc.

# Target Group Attachment — the act of registering an actual EC2 instance INTO that group.

# They are separate resources because AWS designed them to be flexible — the same target group can have instances added and removed dynamically without touching the group's configuration. This is exactly what Auto Scaling does later — it registers new EC2s into the target group automatically when scaling up, and deregisters them when scaling down, without ever changing the target group itself.

resource "aws_lb_target_group_attachment" "app" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.server[count.index].id
  port             = 80
}

# ─── APPLICATION LOAD BALANCER ────────────────────────────────
# The ALB is internet-facing (internal = false) and sits in both
# public subnets. It receives HTTP requests and distributes them
# across healthy instances in the target group (round-robin by default).
#
# ALB operates at Layer 7 (HTTP) meaning it can route based on
# URL path, headers, host — useful later for routing /api to one
# group and /static to another.

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html

# The ALB talks to EC2 instances using their private IPs, not public IPs. The public IPs on the EC2s are only useful if you want to SSH directly or test something.

# Browser
#   ↓  hits ALB DNS (resolves to ALB's public IP)
# ALB node (has its own private IP in the subnet)
#   ↓  forwards to EC2 using PRIVATE IP only
#   ↓  (ALB to EC2 traffic never touches the IGW)
# EC2 private IP (10.0.1.47 or 10.0.2.83)

resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = {
    Name = "${var.project_name}-alb"
  }
}

# ─── LISTENER ─────────────────────────────────────────────────
# The listener watches for incoming requests on port 80.
# When a request arrives, the default action forwards it
# to the target group, which picks an available EC2 instance.

# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-listeners.html
# https://docs.aws.amazon.com/elasticloadbalancing/latest/application/listener-rules.html

# A listener is a process that checks for connection requests, using the protocol and port that you configure. Before you start using your Application Load Balancer, you must add at least one listener. If your load balancer has no listeners, it can't receive traffic from clients. The rules that you define for your listeners determine how the load balancer routes requests to the targets that you register, such as EC2 instances.

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}
