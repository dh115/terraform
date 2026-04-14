# Provider configuration — no backend block, Terraform uses local backend by default
provider "aws" {
  region = var.aws_region
}
