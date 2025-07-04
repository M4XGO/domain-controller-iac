# Variables for Windows Client Module

# Basic configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "main"
}

variable "client_name" {
  description = "Name of the client machine"
  type        = string
  default     = "client1"
}

# Instance configuration
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the instance (empty = latest Windows Server 2022)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "Name of the AWS key pair"
  type        = string
}

# Network configuration
variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
}

variable "associate_public_ip" {
  description = "Associate public IP"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "Allowed CIDR blocks"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Storage configuration
variable "volume_type" {
  description = "EBS volume type"
  type        = string
  default     = "gp2"
}

variable "root_volume_size" {
  description = "Size of root volume in GB"
  type        = number
  default     = 30
}

# Domain configuration
variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
}

variable "domain_controller_ip" {
  description = "IP address of the domain controller"
  type        = string
}

variable "domain_admin_username" {
  description = "Domain administrator username"
  type        = string
  default     = "Administrator"
}

variable "domain_admin_password" {
  description = "Domain administrator password"
  type        = string
  sensitive   = true
}

variable "local_admin_password" {
  description = "Local administrator password"
  type        = string
  sensitive   = true
  default     = "ClientAdmin2024!"
}

# Zabbix configuration
variable "zabbix_server_ip" {
  description = "Zabbix server IP address"
  type        = string
}

variable "enable_zabbix_agent" {
  description = "Enable Zabbix agent installation"
  type        = bool
  default     = true
}

# Security testing configuration
variable "enable_rdp_access" {
  description = "Enable RDP access"
  type        = bool
  default     = true
}

variable "enable_security_testing" {
  description = "Enable configurations for security testing (less secure)"
  type        = bool
  default     = true
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
} 