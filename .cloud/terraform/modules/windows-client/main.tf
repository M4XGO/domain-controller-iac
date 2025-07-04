# Windows Client Module for Domain Join and Monitoring
# Configured for security testing scenarios

# Use same Windows AMI as Domain Controller
data "aws_ami" "windows_client" {
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

# Security Group for Windows Client
resource "aws_security_group" "windows_client" {
  name_prefix = "${var.project_name}-${var.client_name}-"
  vpc_id      = var.vpc_id
  description = "Security group for Windows Client (AD + Zabbix)"

  # RDP access
  dynamic "ingress" {
    for_each = var.enable_rdp_access ? [1] : []
    content {
      description = "RDP"
      from_port   = 3389
      to_port     = 3389
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  # WinRM for management
  ingress {
    description = "WinRM HTTP"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "WinRM HTTPS"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Zabbix Agent port
  dynamic "ingress" {
    for_each = var.enable_zabbix_agent ? [1] : []
    content {
      description = "Zabbix Agent"
      from_port   = 10050
      to_port     = 10050
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
  }

  # SMB/CIFS for file sharing (AD)
  ingress {
    description = "SMB"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # NetBIOS
  ingress {
    description = "NetBIOS Name Service"
    from_port   = 137
    to_port     = 137
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "NetBIOS Datagram Service"
    from_port   = 138
    to_port     = 138
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "NetBIOS Session Service"
    from_port   = 139
    to_port     = 139
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # For security testing - additional ports
  dynamic "ingress" {
    for_each = var.enable_security_testing ? [1] : []
    content {
      description = "Security Testing - Various ports"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
      cidr_blocks = [var.vpc_cidr]
    }
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
    Name = "${var.project_name}-${var.client_name}-sg"
  })
}

# User data script for client configuration
locals {
  user_data = base64encode(templatefile("${path.module}/userdata.ps1", {
    domain_name             = var.domain_name
    domain_controller_ip    = var.domain_controller_ip
    domain_admin_username   = var.domain_admin_username
    domain_admin_password   = var.domain_admin_password
    local_admin_password    = var.local_admin_password
    client_name            = var.client_name
    zabbix_server_ip       = var.zabbix_server_ip
    enable_zabbix_agent    = var.enable_zabbix_agent
    enable_security_testing = var.enable_security_testing
  }))
}

# EC2 Instance for Windows Client
resource "aws_instance" "windows_client" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ami.windows_client.id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.windows_client.id]
  associate_public_ip_address = var.associate_public_ip
  
  # Storage configuration
  root_block_device {
    volume_type = var.volume_type
    volume_size = var.root_volume_size
    encrypted   = true
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.client_name}-root"
    })
  }

  # User data for domain join and configuration
  user_data = local.user_data

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.client_name}"
    Type = "Domain Client"
    Role = "Security Testing"
  })

  lifecycle {
    ignore_changes = [user_data]
  }

  # Wait for domain controller to be ready
  depends_on = [
    aws_security_group.windows_client
  ]
} 