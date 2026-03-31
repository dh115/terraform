# ─── VARIABLES ────────────────────────────────────────────────
# Variables make your config reusable and avoid hardcoding values.
# They are defined here and set in terraform.tfvars.
#
# Variable types: string, number, bool, list, map, object
# "default" makes a variable optional — omit it to make it required.

variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "us-east-1"
}

variable "project_name" { 
  type = string
  default = "myapp" 
}

variable "vpc_cidr" {
  description = "IP range for the VPC"
  type        = string
  default     = "10.255.0.0/16"
}

variable "instance_type" {
  description = "EC2 instance size"
  type        = string
  default     = "t3.micro"
}

variable "instance_ami" {
  description = "EC2 instance AMI"
  type        = string
  default     = "ami-0c3389a4fa5bddaad"
}

variable "instance_count" { 
  type = number
  default = 2 
}

variable "public_key_path" { 
  type = string
  default = "~/.ssh/myapp-key.pub"
}
