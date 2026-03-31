output "alb_dns_name" {
  description = "Open this in your browser to hit the load balancer"
  value       = aws_lb.main.dns_name
}

output "instance_ips" {
  description = "Public IPs of each EC2 instance"
  value       = aws_instance.server[*].public_ip
}