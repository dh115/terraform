resource "aws_s3_bucket" "main" {
  bucket = var.bucket_name

  tags = {
    Project = var.project_id
  }
}
