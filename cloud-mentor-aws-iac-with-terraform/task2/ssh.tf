# Upload the public SSH key to AWS so it can be attached to EC2 instances.
# The private key never leaves your machine — only the public key is stored in AWS.
# The public key value is injected at runtime via TF_VAR_ssh_key — never hardcoded.
resource "aws_key_pair" "main" {
  key_name   = var.aws_keypair_name
  public_key = var.ssh_key

  tags = merge(local.common_tags, {
    Name = var.aws_keypair_name
  })
}
