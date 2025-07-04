# Simple Domain Controller Infrastructure for School Project
# Free Tier Optimized - Cost: ~$0.00/month

terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

# Provider configuration
provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key != "" ? var.aws_access_key : null
  secret_key = var.aws_secret_key != "" ? var.aws_secret_key : null

  default_tags {
    tags = {
      Project   = var.project_name
      Terraform = "true"
      FreeTier  = "optimized"
      Purpose   = "school-project"
    }
  }
}

# Data sources
data "aws_availability_zones" "available" {
  state = "available"
}

# VPC Simple
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

# Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Security Group is now managed by the module

# Key Pair
resource "tls_private_key" "main" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "aws_key_pair" "main" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.main.public_key_openssh

  tags = {
    Name = "${var.project_name}-key"
  }
}

# Save private key
resource "local_file" "private_key" {
  content         = tls_private_key.main.private_key_pem
  filename        = "../../.config/keys/${var.project_name}-key.pem"
  file_permission = "0600"
}

# Domain Controller Instance (FREE TIER)
module "domain_controller" {
  source = "./modules/aws-ec2-windows"

  # Basic configuration
  project_name = var.project_name
  environment  = "main"

  # FREE TIER Instance
  instance_type = var.instance_type  # t2.micro
  ami_id        = var.custom_ami_id
  key_name      = aws_key_pair.main.key_name

  # Network
  vpc_id                  = aws_vpc.main.id
  subnet_id               = aws_subnet.public.id
  vpc_cidr                = var.vpc_cidr
  associate_public_ip     = true
  allowed_cidr_blocks     = ["0.0.0.0/0"]  # École seulement!

  # FREE TIER Storage
  volume_type      = var.volume_type
  root_volume_size = var.root_volume_size

  # Domain config
  domain_name          = var.domain_name
  domain_netbios_name  = var.domain_netbios_name
  admin_username       = var.admin_username
  admin_password       = var.admin_password
  safe_mode_password   = var.safe_mode_password

  # Minimal monitoring
  enable_cloudwatch  = false  # Pas de monitoring pour école
  log_retention_days = 1
  enable_ssm        = false   # Pas de SSM pour école

  common_tags = {
    Project = var.project_name
    Purpose = "school-project"
  }
}

# Windows Client for Security Testing (Optional)
module "windows_client" {
  count  = var.enable_windows_client ? 1 : 0
  source = "./modules/windows-client"

  # Basic configuration
  project_name = var.project_name
  environment  = "main"
  client_name  = var.client_name

  # Instance configuration
  instance_type = var.client_instance_type
  key_name      = aws_key_pair.main.key_name

  # Network
  vpc_id                  = aws_vpc.main.id
  subnet_id               = aws_subnet.public.id
  vpc_cidr                = var.vpc_cidr
  associate_public_ip     = true
  allowed_cidr_blocks     = ["0.0.0.0/0"]  # École seulement!

  # Storage
  volume_type      = var.volume_type
  root_volume_size = var.root_volume_size

  # Domain configuration
  domain_name             = var.domain_name
  domain_controller_ip    = module.domain_controller.private_ip
  domain_admin_username   = var.admin_username
  domain_admin_password   = var.admin_password
  local_admin_password    = var.client_admin_password

  # Zabbix configuration
  zabbix_server_ip     = var.enable_zabbix ? module.zabbix_server[0].private_ip : ""
  enable_zabbix_agent  = var.enable_zabbix

  # Security testing
  enable_security_testing = var.enable_security_testing

  common_tags = {
    Project = var.project_name
    Purpose = "school-project"
  }

  # Dependencies
  depends_on = [
    module.domain_controller,
    module.zabbix_server
  ]
}

# Zabbix Monitoring Server (Optional)
module "zabbix_server" {
  count  = var.enable_zabbix ? 1 : 0
  source = "./modules/zabbix-server"

  # Basic configuration
  project_name = var.project_name
  environment  = "main"

  # Instance configuration
  instance_type = var.zabbix_instance_type
  key_name      = aws_key_pair.main.key_name

  # Network
  vpc_id                  = aws_vpc.main.id
  subnet_id               = aws_subnet.public.id
  vpc_cidr                = var.vpc_cidr
  associate_public_ip     = true
  allowed_cidr_blocks     = ["0.0.0.0/0"]  # École seulement!

  # Storage
  volume_type      = var.volume_type
  root_volume_size = 20  # 20GB for Zabbix (Free Tier)

  # Zabbix config
  zabbix_admin_password = var.zabbix_admin_password
  mysql_root_password   = var.mysql_root_password

  common_tags = {
    Project = var.project_name
    Purpose = "school-project"
    Service = "monitoring"
  }
} 