# Zabbix Server Module
# Ubuntu-based monitoring server for Free Tier

# Ubuntu 22.04 LTS AMI for us-east-1 (known working ID)
locals {
  ubuntu_ami_id = "ami-0866a3c8686eaeeba" # Ubuntu 22.04 LTS in us-east-1
}

# Security Group for Zabbix Server
resource "aws_security_group" "zabbix_server" {
  name_prefix = "${var.project_name}-zabbix-"
  vpc_id      = var.vpc_id
  description = "Security group for Zabbix Server"

  # SSH access
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Zabbix Web Interface
  ingress {
    description = "Zabbix Web (HTTP)"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Zabbix Web Interface (HTTPS)
  ingress {
    description = "Zabbix Web (HTTPS)"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # Zabbix Server port
  ingress {
    description = "Zabbix Server"
    from_port   = 10051
    to_port     = 10051
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Zabbix Agent port (for monitoring itself)
  ingress {
    description = "Zabbix Agent"
    from_port   = 10050
    to_port     = 10050
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SNMP (for network monitoring)
  ingress {
    description = "SNMP"
    from_port   = 161
    to_port     = 161
    protocol    = "udp"
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
    Name = "${var.project_name}-zabbix-sg"
  })
}

# User data script for Zabbix installation
locals {
  user_data = base64encode(templatefile("${path.module}/userdata.sh", {
    mysql_root_password   = var.mysql_root_password
    zabbix_admin_password = var.zabbix_admin_password
    project_name         = var.project_name
  }))
}

# EC2 Instance for Zabbix Server
resource "aws_instance" "zabbix_server" {
  ami                         = local.ubuntu_ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.zabbix_server.id]
  associate_public_ip_address = var.associate_public_ip
  
  # Storage configuration
  root_block_device {
    volume_type = var.volume_type
    volume_size = var.root_volume_size
    encrypted   = true
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-zabbix-root"
    })
  }

  # User data for installation
  user_data = local.user_data

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-zabbix-server"
    Type = "Monitoring Server"
    Service = "Zabbix"
  })

  lifecycle {
    ignore_changes = [user_data]
  }
} 