# Outputs for AWS EC2 Windows Module

output "public_ip" {
  description = "Public IP address of the instance"
  value       = aws_instance.domain_controller.public_ip
}

output "private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.domain_controller.private_ip
}

output "instance_id" {
  description = "Instance ID"
  value       = aws_instance.domain_controller.id
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.domain_controller.id
} 