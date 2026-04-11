# AWS VPC — Terraform Module

Provisions a VPC with three public subnets across separate Availability Zones, an Internet Gateway, and a public route table in `us-east-1`.

---

## Resources Created

| Resource | Name |
|---|---|
| VPC | `cmtr-znhvv6bs-01-vpc` |
| Subnet (us-east-1a) | `cmtr-znhvv6bs-01-subnet-public-a` |
| Subnet (us-east-1b) | `cmtr-znhvv6bs-01-subnet-public-b` |
| Subnet (us-east-1c) | `cmtr-znhvv6bs-01-subnet-public-c` |
| Internet Gateway | `cmtr-znhvv6bs-01-igw` |
| Route Table | `cmtr-znhvv6bs-01-rt` |

---

## File Structure

```
.
├── main.tf           # AWS provider configuration
├── versions.tf       # Terraform and provider version constraints
├── variables.tf      # All input variable declarations
├── terraform.tfvars  # All input values
├── vpc.tf            # VPC, subnets, IGW, route table, associations
└── outputs.tf        # Output definitions
```

---

## Requirements

| Tool | Version |
|---|---|
| Terraform | `>= 1.5.7` |
| AWS Provider | `~> 5.0` |

---

## Inputs

| Variable | Description | Type |
|---|---|---|
| `aws_region` | AWS region to deploy into | `string` |
| `vpc_name` | Name tag for the VPC | `string` |
| `vpc_cidr` | CIDR block for the VPC | `string` |
| `public_subnets` | Map of subnets — key is AZ suffix (a/b/c), value has `az` and `cidr` | `map(object)` |
| `igw_name` | Name tag for the Internet Gateway | `string` |
| `rt_name` | Name tag for the route table | `string` |

---

## Outputs

| Output | Description |
|---|---|
| `vpc_id` | ID of the created VPC |
| `vpc_cidr` | CIDR block of the VPC |
| `public_subnet_ids` | Map of AZ suffix → subnet ID |
| `internet_gateway_id` | ID of the Internet Gateway |
| `public_route_table_id` | ID of the public route table |

---

## Usage

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

To destroy all resources:

```bash
terraform destroy
```
