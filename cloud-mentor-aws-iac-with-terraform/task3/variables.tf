variable "aws_region" {
  description = "AWS region where all resources will be deployed."
  type        = string
}

variable "project_id" {
  description = "Unique sandbox ID injected by the course platform. Used for tagging."
  type        = string
}

variable "bucket_name" {
  description = "AWS S3 bucket name"
  type        = string
}
