# Outputs for Simple Domain Controller Project

# Instance Information
output "domain_controller_public_ip" {
  description = "Public IP of Domain Controller"
  value       = module.domain_controller.public_ip
}

output "domain_controller_private_ip" {
  description = "Private IP of Domain Controller"
  value       = module.domain_controller.private_ip
}

output "instance_id" {
  description = "Instance ID"
  value       = module.domain_controller.instance_id
}

# Domain Information
output "domain_name" {
  description = "Active Directory domain name"
  value       = var.domain_name
}

output "admin_username" {
  description = "Administrator username"
  value       = var.admin_username
}

# Connection Instructions
output "rdp_connection" {
  description = "RDP connection instructions"
  value = "Connect via RDP to: ${module.domain_controller.public_ip}:3389"
}

output "connection_info" {
  description = "Complete connection information"
  value = {
    public_ip  = module.domain_controller.public_ip
    private_ip = module.domain_controller.private_ip
    rdp_port   = 3389
    domain     = var.domain_name
    username   = "${var.domain_netbios_name}\\${var.admin_username}"
  }
  sensitive = false
}

# Key Information
output "ssh_key_location" {
  description = "Location of the SSH private key"
  value       = "../.config/keys/${var.project_name}-key.pem"
}

# Simple Summary
output "summary" {
  description = "Project summary"
  value = {
    project           = var.project_name
    instance_type     = var.instance_type
    cost_per_month    = "~$0.00 (Free Tier)"
    domain_controller = module.domain_controller.public_ip
    ready_to_use      = "Connect via RDP and join your computers to ${var.domain_name}"
  }
} 