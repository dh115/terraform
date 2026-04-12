variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
}

variable "project_id" {
  description = "Unique sandbox ID injected by the course platform. Used for tagging and name derivation."
  type        = string
}

variable "aws_keypair_name" {
  description = "Name of the AWS key pair resource. Injected by the course platform."
  type        = string
}

variable "aws_instance_name" {
  description = "Name tag for the EC2 instance. Injected by the course platform."
  type        = string
}

variable "aws_security_group_name" {
  description = "Name of the pre-existing security group allowing SSH access. Created by CloudFormation."
  type        = string
}

variable "instance_ami" {
  description = "AMI ID for the EC2 instance. Should match the target AWS region."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type."
  type        = string
}

variable "ssh_key" {
  description = "Public SSH key for EC2 access." # Must be injected via TF_VAR_ssh_key environment variable — never stored in .tfvars or version control."
  type        = string
}
