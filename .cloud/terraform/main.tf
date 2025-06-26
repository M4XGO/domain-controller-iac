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
  region = var.aws_region

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

# Security Group for Domain Controller
resource "aws_security_group" "domain_controller" {
  name_prefix = "${var.project_name}-dc-"
  vpc_id      = aws_vpc.main.id
  description = "Security group for Domain Controller"

  # RDP access
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ATTENTION: Pour école seulement!
  }

  # WinRM HTTPS (for management)
  ingress {
    description = "WinRM HTTPS"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS (ouvert pour clients locaux)
  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Pour clients locaux
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]  # Pour clients locaux
  }

  # Active Directory basics
  ingress {
    description = "LDAP"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Kerberos"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound traffic
  egress {
    description = "All outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-dc-sg"
  }
}

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
  filename        = "../.config/keys/${var.project_name}-key.pem"
  file_permission = "0600"
}

# Domain Controller Instance (FREE TIER)
module "domain_controller" {
  source = "../.infra/modules/aws-ec2-windows"

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