# Cloud-Mentor: AWS IaC with Terraform — Sandbox Lab

## Overview

Terraform configuration written as part of the **Cloud-Mentor: AWS IaC with Terraform**
instructor-led sandbox course. Provisions an EC2 instance into a pre-existing VPC
environment using Terraform data sources, SSH key pair management, and consistent
resource tagging.

The sandbox is ephemeral — all resources are automatically destroyed at session end.

---

## Architecture

```
CloudFormation (pre-existing)        Terraform (this project)
─────────────────────────────        ────────────────────────
VPC                          ──┐
Public Subnets               ──┼──► EC2 Instance
Security Group (SSH)         ──┘         │
                                    Key Pair ◄── TF_VAR_ssh_key (env)
```

---

## Resources

| Resource | Managed by | Description |
|---|---|---|
| VPC | CloudFormation | Referenced via data source |
| Public Subnets | CloudFormation | Referenced via data source |
| Security Group | CloudFormation | Referenced via data source |
| `aws_key_pair` | Terraform | SSH public key uploaded to AWS |
| `aws_instance` | Terraform | EC2 instance in public subnet |

---

## File Structure

```
.
├── main.tf            # Provider, locals, data sources
├── variables.tf       # All variable declarations
├── ssh.tf             # SSH key pair resource
├── ec2.tf             # EC2 instance resource
├── outputs.tf         # Output values (public IP, SSH command)
├── terraform.tfvars   # Variable values (sandbox-safe — see below)
└── README.md
```

---

## Why `.tfvars` Is Committed

All values in `terraform.tfvars` are either non-sensitive (region, instance type) or
sandbox-scoped (ephemeral IDs that expire with the session). No production credentials
or secrets are stored here.

> **Do not replicate this in real-world projects.** Sensitive `.tfvars` files must be
> excluded via `.gitignore` and managed via a secrets manager or CI/CD variable store.

---

## SSH Key

The public SSH key is intentionally excluded from version control. Inject it at runtime:

```bash
export TF_VAR_ssh_key="$(cat ~/.ssh/id_rsa.pub)"
```

---

## Usage

```bash
# 1. Inject SSH public key
export TF_VAR_ssh_key="$(cat ~/.ssh/id_rsa.pub)"

# 2. Initialise working directory
terraform init

# 3. Format and validate
terraform fmt
terraform validate

# 4. Preview changes
terraform plan

# 5. Deploy
terraform apply

# 6. Connect (IP and full command printed as outputs)
ssh -i ~/.ssh/id_rsa ec2-user@<instance_public_ip>
```

---

## Outputs

After `terraform apply`, the following values are printed:

| Output | Description |
|---|---|
| `instance_public_ip` | Public IP of the EC2 instance |
| `instance_id` | AWS instance ID |
| `ssh_command` | Ready-to-use SSH connection command |

---

## Tags

All resources are tagged with:

| Key | Value |
|---|---|
| `Project` | `epam-tf-lab` |
| `ID` | `<project_id>` |

---

## Disclaimer

This project is for educational purposes only. All infrastructure runs in a sandboxed,
temporary environment unaffiliated with any production system.
