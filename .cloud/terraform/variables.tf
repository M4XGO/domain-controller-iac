# Variables for Simple Domain Controller Project
# School Project - Free Tier Only

# Project Configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "domain-controller"
}

# AWS Configuration
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# AWS Credentials (optional - for project isolation)
variable "aws_access_key" {
  description = "AWS Access Key ID (optional, leave empty to use default profile)"
  type        = string
  default     = ""
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS Secret Access Key (optional, leave empty to use default profile)"
  type        = string
  default     = ""
  sensitive   = true
}

# Network Configuration
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
  default     = "10.0.1.0/24"
}

# Instance Configuration (Free Tier)
variable "instance_type" {
  description = "EC2 instance type (Free Tier: t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "custom_ami_id" {
  description = "Custom AMI ID (empty = use latest Windows Server 2022)"
  type        = string
  default     = ""
}

# Storage Configuration (Free Tier)
variable "volume_type" {
  description = "EBS volume type (Free Tier: gp2)"
  type        = string
  default     = "gp2"
}

variable "root_volume_size" {
  description = "Size of root volume in GB (Free Tier: max 30GB)"
  type        = number
  default     = 25
}

# Domain Configuration
variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
  default     = "school.local"
}

variable "domain_netbios_name" {
  description = "NetBIOS name for the domain"
  type        = string
  default     = "SCHOOL"
}

variable "admin_username" {
  description = "Domain administrator username"
  type        = string
  default     = "Administrator"
}

variable "admin_password" {
  description = "Domain administrator password"
  type        = string
  sensitive   = true
  default     = "ChangeMe2024!"
}

variable "safe_mode_password" {
  description = "Directory Services Restore Mode password"
  type        = string
  sensitive   = true
  default     = "SafeMode2024!"
}

# Zabbix Configuration
variable "enable_zabbix" {
  description = "Enable Zabbix monitoring server"
  type        = bool
  default     = true
}

variable "zabbix_instance_type" {
  description = "EC2 instance type for Zabbix (Free Tier: t2.micro)"
  type        = string
  default     = "t2.micro"
}

variable "zabbix_admin_password" {
  description = "Zabbix admin password"
  type        = string
  sensitive   = true
  default     = "ZabbixAdmin2024!"
}

variable "mysql_root_password" {
  description = "MySQL root password for Zabbix"
  type        = string
  sensitive   = true
  default     = "MySQLRoot2024!"
} 