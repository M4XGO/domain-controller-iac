# Variables for Zabbix Server Module

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

# Instance configuration
variable "instance_type" {
  description = "EC2 instance type for Zabbix server"
  type        = string
  default     = "t2.micro"
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
  default     = 20
}

# Zabbix configuration
variable "zabbix_admin_password" {
  description = "Zabbix admin password"
  type        = string
  sensitive   = true
  default     = "ZabbixAdmin2024!"
}

variable "mysql_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
  default     = "MySQLRoot2024!"
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
} 