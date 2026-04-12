output "instance_public_ip" {
  description = "Public IP address of the EC2 instance. Use this to SSH into the instance."
  value       = aws_instance.server.public_ip
}

output "instance_id" {
  description = "EC2 instance ID."
  value       = aws_instance.server.id
}

output "ssh_command" {
  description = "Ready-to-use SSH command to connect to the instance."
  value       = "ssh -i ~/.ssh/id_rsa ec2-user@${aws_instance.server.public_ip}"
}
