# Terraform

Personal Terraform monorepo — each subdirectory is a standalone project with its own state and configuration.

## Structure

```
terraform/
├── epam-infrastructure-as-code/   # hands-on IaC learning project
└── ...                              # future projects
```

## Usage

Each project is independent. Navigate into the project directory and run Terraform from there:

```bash
cd <project-name>
terraform init
terraform plan
terraform apply
```

## Requirements

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- SSH key pair generated locally before applying any EC2 project (optional)
