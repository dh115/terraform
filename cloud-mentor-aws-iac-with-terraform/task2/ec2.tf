# EC2 instance deployed into the first available public subnet.
# Attached to the pre-existing SSH security group and the key pair defined in ssh.tf.
resource "aws_instance" "server" {
  ami           = var.instance_ami
  instance_type = var.instance_type

  # Place instance in a public subnet discovered via data source.
  # ids[0] selects the first available — sufficient for a single-instance lab setup.
  subnet_id = data.aws_subnets.public.ids[0]

  # Explicitly request a public IP even though the subnet auto-assigns one.
  # Being explicit makes the intent clear and prevents surprises if subnet defaults change.
  associate_public_ip_address = true

  # Reference the security group by ID, not name.
  # vpc_security_group_ids is required (not security_groups) for VPC-based instances.
  vpc_security_group_ids = [data.aws_security_group.ssh.id]

  # Key pair for SSH access — defined in ssh.tf.
  key_name = aws_key_pair.main.key_name

  tags = merge(local.common_tags, {
    Name = var.aws_instance_name
  })
}
