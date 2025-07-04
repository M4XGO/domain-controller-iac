# AWS EC2 Windows Module for Domain Controller
# Free Tier Optimized

# Data source for latest Windows Server 2022 AMI
data "aws_ami" "windows_server_2022" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["Windows_Server-2022-English-Full-Base-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Domain Controller
resource "aws_security_group" "domain_controller" {
  name_prefix = "${var.project_name}-dc-"
  vpc_id      = var.vpc_id
  description = "Security group for Domain Controller"

  # RDP access
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # WinRM HTTPS (for management)
  ingress {
    description = "WinRM HTTPS"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS TCP
  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # DNS UDP
  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # LDAP
  ingress {
    description = "LDAP"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kerberos
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

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-dc-sg"
  })
}

# User data script for Windows domain controller setup
locals {
  user_data = base64encode(templatefile("${path.module}/userdata.ps1", {
    domain_name         = var.domain_name
    domain_netbios_name = var.domain_netbios_name
    admin_password      = var.admin_password
    safe_mode_password  = var.safe_mode_password
  }))
}

# EC2 Instance
resource "aws_instance" "domain_controller" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.windows_server_2022.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.domain_controller.id]
  associate_public_ip_address = var.associate_public_ip
  
  # Storage configuration
  root_block_device {
    volume_type = var.volume_type
    volume_size = var.root_volume_size
    encrypted   = true
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-dc-root"
    })
  }

  # User data for initial setup
  user_data = local.user_data

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-domain-controller"
    Type = "Domain Controller"
  })

  lifecycle {
    ignore_changes = [user_data]
  }
} 