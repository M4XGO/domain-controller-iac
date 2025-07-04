# Variables for AWS EC2 Windows Module
# Domain Controller specific

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
  default     = 25
}

# Domain configuration
variable "domain_name" {
  description = "Active Directory domain name"
  type        = string
}

variable "domain_netbios_name" {
  description = "NetBIOS name for the domain"
  type        = string
}

variable "admin_username" {
  description = "Administrator username"
  type        = string
  default     = "Administrator"
}

variable "admin_password" {
  description = "Administrator password"
  type        = string
  sensitive   = true
}

variable "safe_mode_password" {
  description = "Safe mode password"
  type        = string
  sensitive   = true
}

# Optional features
variable "enable_cloudwatch" {
  description = "Enable CloudWatch monitoring"
  type        = bool
  default     = false
}

variable "log_retention_days" {
  description = "Log retention in days"
  type        = number
  default     = 1
}

variable "enable_ssm" {
  description = "Enable SSM"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default     = {}
} 