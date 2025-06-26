# Outputs for AWS EC2 Windows Module - Free Tier Optimized

# Instance information
output "instance_id" {
  description = "Domain Controller instance ID"
  value       = aws_instance.domain_controller.id
}

output "instance_arn" {
  description = "Domain Controller instance ARN"
  value       = aws_instance.domain_controller.arn
}

output "private_ip" {
  description = "Domain Controller private IP address"
  value       = aws_instance.domain_controller.private_ip
}

output "public_ip" {
  description = "Domain Controller public IP address (if assigned)"
  value       = aws_instance.domain_controller.public_ip
}

output "private_dns" {
  description = "Domain Controller private DNS name"
  value       = aws_instance.domain_controller.private_dns
}

output "public_dns" {
  description = "Domain Controller public DNS name"
  value       = aws_instance.domain_controller.public_dns
}

# Security and networking
output "security_group_id" {
  description = "Domain Controller security group ID"
  value       = aws_security_group.domain_controller.id
}

output "security_group_arn" {
  description = "Domain Controller security group ARN"
  value       = aws_security_group.domain_controller.arn
}

# IAM resources
output "iam_role_name" {
  description = "Domain Controller IAM role name"
  value       = aws_iam_role.domain_controller.name
}

output "iam_role_arn" {
  description = "Domain Controller IAM role ARN"
  value       = aws_iam_role.domain_controller.arn
}

output "instance_profile_name" {
  description = "Domain Controller instance profile name"
  value       = aws_iam_instance_profile.domain_controller.name
}

# Domain configuration
output "domain_name" {
  description = "Active Directory domain name"
  value       = var.domain_name
}

output "domain_netbios_name" {
  description = "Active Directory NetBIOS domain name"
  value       = var.domain_netbios_name
}

output "admin_username" {
  description = "Domain administrator username"
  value       = var.admin_username
}

# DNS Configuration for clients
output "dns_server_ip" {
  description = "DNS server IP (Domain Controller IP for client configuration)"
  value       = aws_instance.domain_controller.private_ip
}

# Monitoring and logging (Free Tier)
output "cloudwatch_log_group_name" {
  description = "CloudWatch log group name"
  value       = var.enable_cloudwatch ? aws_cloudwatch_log_group.domain_controller[0].name : null
}

output "cloudwatch_log_group_arn" {
  description = "CloudWatch log group ARN"
  value       = var.enable_cloudwatch ? aws_cloudwatch_log_group.domain_controller[0].arn : null
}

# Systems Manager
output "ssm_document_name" {
  description = "SSM document name for domain setup"
  value       = var.enable_ssm ? aws_ssm_document.domain_setup[0].name : null
}

# Connection information for Ansible
output "ansible_connection_info" {
  description = "Connection information for Ansible"
  value = {
    host          = aws_instance.domain_controller.private_ip
    user          = var.admin_username
    connection    = "winrm"
    winrm_port    = 5986
    winrm_scheme  = "https"
    validate_certs = false
  }
  sensitive = false
}

# Cost optimization info (Free Tier)
output "free_tier_optimization" {
  description = "Free Tier optimization information"
  value = {
    instance_type    = var.instance_type
    volume_type      = var.volume_type
    volume_size_gb   = var.root_volume_size
    monitoring       = "basic"  # No detailed monitoring
    estimated_cost   = "~$0.00/month (Free Tier eligible)"
  }
}

# Complete infrastructure summary
output "infrastructure_summary" {
  description = "Complete infrastructure summary"
  value = {
    project_name     = var.project_name
    environment      = var.environment
    instance_id      = aws_instance.domain_controller.id
    private_ip       = aws_instance.domain_controller.private_ip
    public_ip        = aws_instance.domain_controller.public_ip
    domain_fqdn      = var.domain_name
    security_group   = aws_security_group.domain_controller.id
    iam_role        = aws_iam_role.domain_controller.name
    free_tier_optimized = true
  }
} 