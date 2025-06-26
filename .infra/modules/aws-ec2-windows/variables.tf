# Variables for AWS EC2 Windows Module - Free Tier Optimized

# Project configuration
variable "project_name" {
  description = "Name of the project"
  type        = string
  
  validation {
    condition     = length(var.project_name) > 0 && length(var.project_name) <= 20
    error_message = "Project name must be between 1 and 20 characters."
  }
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod."
  }
}

# Instance configuration (Free Tier optimized)
variable "instance_type" {
  description = "EC2 instance type (Free Tier: t2.micro)"
  type        = string
  default     = "t2.micro"
  
  validation {
    condition = contains([
      "t2.micro",     # Free Tier eligible
      "t3.micro",     # Burstable performance
      "t3.small"      # If more performance needed
    ], var.instance_type)
    error_message = "Instance type must be Free Tier compatible (t2.micro recommended)."
  }
}

variable "ami_id" {
  description = "Custom AMI ID (leave empty to use latest Windows Server 2022)"
  type        = string
  default     = ""
}

variable "key_name" {
  description = "EC2 Key Pair name for emergency access"
  type        = string
  default     = ""
}

# Network configuration
variable "vpc_id" {
  description = "VPC ID where the instance will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where the instance will be deployed"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR block for security group rules"
  type        = string
}

variable "associate_public_ip" {
  description = "Associate a public IP address with the instance"
  type        = bool
  default     = true
}

variable "allowed_cidr_blocks" {
  description = "CIDR blocks allowed for RDP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

# Storage configuration (Free Tier optimized)
variable "volume_type" {
  description = "EBS volume type (Free Tier: gp2)"
  type        = string
  default     = "gp2"
  
  validation {
    condition     = contains(["gp2", "gp3"], var.volume_type)
    error_message = "Volume type must be gp2 (Free Tier) or gp3."
  }
}

variable "root_volume_size" {
  description = "Size of the root volume in GB (Free Tier: max 30GB, recommended 25GB)"
  type        = number
  default     = 25
  
  validation {
    condition     = var.root_volume_size >= 20 && var.root_volume_size <= 30
    error_message = "Root volume size must be between 20GB and 30GB for Free Tier."
  }
}

# Domain configuration
variable "domain_name" {
  description = "Active Directory domain name (FQDN)"
  type        = string
  
  validation {
    condition     = can(regex("^[a-zA-Z0-9-\\.]+\\.[a-zA-Z]{2,}$", var.domain_name))
    error_message = "Domain name must be a valid FQDN (e.g., example.local)."
  }
}

variable "domain_netbios_name" {
  description = "NetBIOS name for the domain (max 15 characters)"
  type        = string
  
  validation {
    condition     = length(var.domain_netbios_name) > 0 && length(var.domain_netbios_name) <= 15
    error_message = "NetBIOS name must be between 1 and 15 characters."
  }
}

variable "admin_username" {
  description = "Domain administrator username"
  type        = string
  default     = "Administrator"
  
  validation {
    condition     = length(var.admin_username) >= 3 && length(var.admin_username) <= 20
    error_message = "Admin username must be between 3 and 20 characters."
  }
}

variable "admin_password" {
  description = "Domain administrator password (sensitive)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.admin_password) >= 8
    error_message = "Admin password must be at least 8 characters long."
  }
}

variable "safe_mode_password" {
  description = "Directory Services Restore Mode password (sensitive)"
  type        = string
  sensitive   = true
  
  validation {
    condition     = length(var.safe_mode_password) >= 8
    error_message = "Safe mode password must be at least 8 characters long."
  }
}

# Monitoring and logging (Free Tier)
variable "enable_cloudwatch" {
  description = "Enable CloudWatch monitoring (Free Tier included)"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch logs retention period in days (Free Tier: 1-7 days recommended)"
  type        = number
  default     = 1
  
  validation {
    condition     = contains([1, 3, 5, 7, 14, 30], var.log_retention_days)
    error_message = "Log retention must be one of: 1, 3, 5, 7, 14, 30 days."
  }
}

# Systems Manager (Free Tier)
variable "enable_ssm" {
  description = "Enable Systems Manager (Free Tier included)"
  type        = bool
  default     = true
}

# Tagging
variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "dev"
    Project     = "domain-controller"
  }
}
} 