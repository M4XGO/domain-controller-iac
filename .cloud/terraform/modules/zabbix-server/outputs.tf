# Outputs for Zabbix Server Module

output "public_ip" {
  description = "Public IP address of the Zabbix server"
  value       = aws_instance.zabbix_server.public_ip
}

output "private_ip" {
  description = "Private IP address of the Zabbix server"
  value       = aws_instance.zabbix_server.private_ip
}

output "instance_id" {
  description = "Instance ID of the Zabbix server"
  value       = aws_instance.zabbix_server.id
}

output "security_group_id" {
  description = "Security group ID for Zabbix server"
  value       = aws_security_group.zabbix_server.id
}

output "web_url" {
  description = "Zabbix web interface URL"
  value       = "http://${aws_instance.zabbix_server.public_ip}/zabbix"
}

output "web_url_https" {
  description = "Zabbix web interface URL (HTTPS)"
  value       = "https://${aws_instance.zabbix_server.public_ip}/zabbix"
} 