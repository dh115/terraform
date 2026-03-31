# Epam Infrastructure as Code course

Hands-on AWS infrastructure built step by step while learning Terraform. Each concept is introduced incrementally — nothing is added before it is understood.

## What this builds

A 3-tier web application infrastructure on AWS:

```
Internet
    ↓
Internet Gateway
    ↓
ALB (public subnets across 2 AZs)
    ↓
EC2 instances (one per AZ)
```

## Resources

| Resource | Description |
|---|---|
| VPC | Isolated network — 10.0.0.0/16 |
| Public subnets | Two subnets across us-east-1a and us-east-1b |
| Internet Gateway | Connects VPC to the internet |
| Route table | Routes outbound traffic through the IGW |
| Security group (ALB) | Allows HTTP from internet |
| Security group (EC2) | Allows HTTP from ALB only, SSH for access |
| EC2 instances | t2.micro Amazon Linux 2, one per AZ |
| ALB | Distributes traffic across EC2 instances |
| Target group | Registers EC2s with health checks |

## Usage

```bash
# generate SSH key pair before first apply
ssh-keygen -t ed25519 -f ~/.ssh/myapp-key

terraform init
terraform plan
terraform apply

# connect to an instance
ssh -i ~/.ssh/myapp-key ec2-user@<instance_public_ip>

# destroy when done to avoid charges
terraform destroy
```

## Variables

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region | us-east-1 |
| `project_name` | Prefix for all resource names | myapp |
| `vpc_cidr` | VPC IP range | 10.0.0.0/16 |
| `instance_ami` | AMI ID for EC2 instances | required |
| `instance_type` | EC2 instance size | t2.micro |
| `instance_count` | Number of EC2 instances | 2 |
| `key_name` | SSH key pair name in AWS | required |

## Cost

All resources in this project are either free tier or near-zero cost.
Destroy after each session — the ALB charges ~$0.008/hr even when idle.

```bash
terraform destroy
```
