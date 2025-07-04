# Outputs for Windows Client Module

output "public_ip" {
  description = "Public IP address of the Windows client"
  value       = aws_instance.windows_client.public_ip
}

output "private_ip" {
  description = "Private IP address of the Windows client"
  value       = aws_instance.windows_client.private_ip
}

output "instance_id" {
  description = "Instance ID of the Windows client"
  value       = aws_instance.windows_client.id
}

output "security_group_id" {
  description = "Security group ID for Windows client"
  value       = aws_security_group.windows_client.id
}

output "computer_name" {
  description = "Computer name in the domain"
  value       = var.client_name
}

output "domain_fqdn" {
  description = "Fully qualified domain name"
  value       = "${var.client_name}.${var.domain_name}"
}

output "rdp_connection" {
  description = "RDP connection information"
  value = {
    address  = aws_instance.windows_client.public_ip
    port     = 3389
    username = "Administrator"
    domain   = var.domain_name
  }
}

output "security_testing_info" {
  description = "Information for security testing"
  value = var.enable_security_testing ? {
    test_users = [
      { username = "testuser", password = "Password123" },
      { username = "serviceaccount", password = "Service123" },
      { username = "backup_admin", password = "backup123" }
    ]
    vulnerable_services = [
      "LLMNR (UDP 5355)",
      "NetBIOS (UDP 137-138, TCP 139)",
      "SMBv1 (TCP 445)",
      "Weak audit policies"
    ]
    attack_vectors = [
      "Responder attacks (LLMNR/NetBIOS)",
      "Hash dumping (mimikatz, secretsdump)",
      "Credential spraying",
      "Pass-the-hash attacks",
      "Lateral movement testing"
    ]
  } : null
}

output "zabbix_info" {
  description = "Zabbix monitoring information"
  value = var.enable_zabbix_agent ? {
    server_ip = var.zabbix_server_ip
    agent_port = 10050
    hostname = "${var.client_name}.${var.domain_name}"
    status = "Agent installed and configured"
  } : null
} 