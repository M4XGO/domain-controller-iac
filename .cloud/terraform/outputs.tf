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
  value       = "../../.config/keys/${var.project_name}-key.pem"
}

# Simple Summary
output "summary" {
  description = "Project summary"
  value = {
    project           = var.project_name
    instance_type     = var.instance_type
    cost_per_month    = "~$0.00 (Free Tier)"
    domain_controller = module.domain_controller.public_ip
    zabbix_server     = var.enable_zabbix ? module.zabbix_server[0].public_ip : "disabled"
    windows_client    = var.enable_windows_client ? module.windows_client[0].public_ip : "disabled"
    ready_to_use      = "All machines configured for security testing with AD domain ${var.domain_name}"
  }
}

# Zabbix Outputs (when enabled)
output "zabbix_public_ip" {
  description = "Public IP of Zabbix Server"
  value       = var.enable_zabbix ? module.zabbix_server[0].public_ip : null
}

output "zabbix_private_ip" {
  description = "Private IP of Zabbix Server"
  value       = var.enable_zabbix ? module.zabbix_server[0].private_ip : null
}

output "zabbix_web_url" {
  description = "Zabbix web interface URL"
  value       = var.enable_zabbix ? module.zabbix_server[0].web_url : null
}

output "zabbix_info" {
  description = "Zabbix connection information"
  value = var.enable_zabbix ? {
    web_interface = module.zabbix_server[0].web_url
    default_login = "Admin / zabbix (CHANGE THIS!)"
    ssh_access    = "ssh -i ../../.config/keys/${var.project_name}-key.pem ubuntu@${module.zabbix_server[0].public_ip}"
  } : null
}

# Windows Client Outputs (when enabled)
output "windows_client_public_ip" {
  description = "Public IP of Windows Client"
  value       = var.enable_windows_client ? module.windows_client[0].public_ip : null
}

output "windows_client_private_ip" {
  description = "Private IP of Windows Client"
  value       = var.enable_windows_client ? module.windows_client[0].private_ip : null
}

output "windows_client_rdp" {
  description = "RDP connection info for Windows Client"
  value = var.enable_windows_client ? {
    address  = module.windows_client[0].public_ip
    port     = 3389
    username = "Administrator"
    password = var.client_admin_password
    domain   = var.domain_name
  } : null
  sensitive = true
}

output "security_testing_info" {
  description = "Security testing information and attack vectors"
  value = var.enable_windows_client && var.enable_security_testing ? {
    target_machine = module.windows_client[0].public_ip
    domain_info = {
      domain_name = var.domain_name
      dc_ip      = module.domain_controller.private_ip
      client_ip  = module.windows_client[0].private_ip
    }
    test_accounts = {
      domain_admin = {
        username = var.admin_username
        password = var.admin_password
        domain   = var.domain_name
      }
      local_accounts = [
        { username = "testuser", password = "Password123" },
        { username = "serviceaccount", password = "Service123" },
        { username = "backup_admin", password = "backup123" }
      ]
    }
    attack_scenarios = [
      "1. LLMNR/NetBIOS Responder attacks",
      "2. Hash dumping with mimikatz or secretsdump",
      "3. Pass-the-hash attacks", 
      "4. Credential spraying",
      "5. Lateral movement testing",
      "6. DCSync attacks (if domain admin compromised)"
    ]
    monitoring = var.enable_zabbix ? {
      zabbix_url = "http://${module.zabbix_server[0].public_ip}/zabbix"
      note = "Monitor attacks in real-time via Zabbix"
    } : null
  } : null
  sensitive = true
}

output "penetration_testing_guide" {
  description = "Quick guide for penetration testing"
  value = var.enable_windows_client ? {
    step_1 = "RDP to client: ${var.enable_windows_client ? module.windows_client[0].public_ip : "N/A"}:3389"
    step_2 = "Use domain credentials: ${var.domain_name}\\${var.admin_username}"
    step_3 = "Run Responder attacks against LLMNR/NetBIOS"
    step_4 = "Extract hashes and attempt lateral movement"
    step_5 = "Monitor alerts in Zabbix dashboard"
    warning = "⚠️  FOR EDUCATIONAL PURPOSES ONLY - AUTHORIZED TESTING ONLY"
  } : null
} 