# AWS EC2 Windows Module - Free Tier Optimized
# Module pour Domain Controller Windows Server 2022 optimisé Free Tier

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

# AMI Windows Server 2022 (Free Tier eligible)
data "aws_ami" "windows" {
  count       = var.ami_id == "" ? 1 : 0
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

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Security Group for Domain Controller (Free Tier optimized)
resource "aws_security_group" "domain_controller" {
  name_prefix = "${var.project_name}-${var.environment}-dc-"
  vpc_id      = var.vpc_id
  description = "Security group for Domain Controller (Free Tier)"

  # RDP access (restricted to admin IPs)
  ingress {
    description = "RDP"
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  # WinRM HTTP (for Ansible)
  ingress {
    description = "WinRM HTTP"
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # WinRM HTTPS (for Ansible)
  ingress {
    description = "WinRM HTTPS"
    from_port   = 5986
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # DNS (TCP and UDP)
  ingress {
    description = "DNS TCP"
    from_port   = 53
    to_port     = 53
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "DNS UDP"
    from_port   = 53
    to_port     = 53
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kerberos
  ingress {
    description = "Kerberos TCP"
    from_port   = 88
    to_port     = 88
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Kerberos UDP"
    from_port   = 88
    to_port     = 88
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # LDAP
  ingress {
    description = "LDAP"
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # LDAPS
  ingress {
    description = "LDAPS"
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # SMB/CIFS
  ingress {
    description = "SMB"
    from_port   = 445
    to_port     = 445
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Kerberos Password Change
  ingress {
    description = "Kerberos Password TCP"
    from_port   = 464
    to_port     = 464
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Kerberos Password UDP"
    from_port   = 464
    to_port     = 464
    protocol    = "udp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Global Catalog
  ingress {
    description = "Global Catalog"
    from_port   = 3268
    to_port     = 3268
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  ingress {
    description = "Global Catalog SSL"
    from_port   = 3269
    to_port     = 3269
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # RPC Endpoint Mapper
  ingress {
    description = "RPC Endpoint Mapper"
    from_port   = 135
    to_port     = 135
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Dynamic RPC (Free Tier: only essential range)
  ingress {
    description = "Dynamic RPC"
    from_port   = 49152
    to_port     = 49200  # Reduced range for Free Tier
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  # Outbound traffic
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-dc-sg"
    Type = "Security Group"
  })
}

# IAM Role for Domain Controller (Free Tier)
resource "aws_iam_role" "domain_controller" {
  name = "${var.project_name}-${var.environment}-dc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

# IAM Policy for Free Tier services
resource "aws_iam_role_policy" "domain_controller" {
  name = "${var.project_name}-${var.environment}-dc-policy"
  role = aws_iam_role.domain_controller.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          # CloudWatch (Free Tier)
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLog*",
          
          # SSM (Free Tier)
          "ssm:GetParameter",
          "ssm:GetParameters",
          "ssm:GetParametersByPath",
          "ssm:UpdateInstanceInformation",
          "ssm:SendCommand",
          
          # EC2 (Free operations)
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "ec2:CreateTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Instance profile
resource "aws_iam_instance_profile" "domain_controller" {
  name = "${var.project_name}-${var.environment}-dc-profile"
  role = aws_iam_role.domain_controller.name

  tags = var.common_tags
}

# CloudWatch Log Group (Free Tier - minimal retention)
resource "aws_cloudwatch_log_group" "domain_controller" {
  count             = var.enable_cloudwatch ? 1 : 0
  name              = "/aws/ec2/${var.project_name}-${var.environment}-dc"
  retention_in_days = var.log_retention_days

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-dc-logs"
  })
}

# EC2 Instance - Domain Controller (FREE TIER t2.micro)
resource "aws_instance" "domain_controller" {
  # FREE TIER CONFIGURATION
  ami           = var.ami_id != "" ? var.ami_id : data.aws_ami.windows[0].id
  instance_type = var.instance_type  # t2.micro for Free Tier
  
  # Network configuration
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [aws_security_group.domain_controller.id]
  associate_public_ip_address = var.associate_public_ip
  
  # IAM
  iam_instance_profile = aws_iam_instance_profile.domain_controller.name
  
  # Key pair for emergency access
  key_name = var.key_name != "" ? var.key_name : null

  # FREE TIER STORAGE - Single volume optimized
  root_block_device {
    volume_type           = var.volume_type  # gp2 for Free Tier
    volume_size           = var.root_volume_size  # 25GB max for Free Tier
    delete_on_termination = true
    encrypted             = true  # Free encryption
    
    tags = merge(var.common_tags, {
      Name = "${var.project_name}-${var.environment}-dc-root"
      Type = "Root Volume"
    })
  }

  # User data for initial setup (Free Tier optimized)
  user_data = base64encode(templatefile("${path.module}/templates/windows_userdata.ps1", {
    domain_name           = var.domain_name
    safe_mode_password    = var.safe_mode_password
    admin_username        = var.admin_username
    admin_password        = var.admin_password
    log_group_name        = var.enable_cloudwatch ? aws_cloudwatch_log_group.domain_controller[0].name : ""
    enable_cloudwatch     = var.enable_cloudwatch
    enable_ssm           = var.enable_ssm
    # Free Tier: no separate volumes
    data_drive_letter    = "C"  # Use root volume
    logs_drive_letter    = "C"  # Use root volume
  }))

  # Monitoring (Free Tier basic only)
  monitoring = false  # Detailed monitoring costs extra

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-${var.environment}-dc"
    Type = "Domain Controller"
    OS   = "Windows Server 2022"
    Role = "Active Directory"
  })

  lifecycle {
    ignore_changes = [
      ami,  # Prevent accidental updates
      user_data  # Prevent recreation on user_data changes
    ]
  }
}

# Systems Manager Association (Free Tier)
resource "aws_ssm_association" "domain_controller_setup" {
  count = var.enable_ssm ? 1 : 0
  name  = aws_ssm_document.domain_setup[0].name

  targets {
    key    = "InstanceIds"
    values = [aws_instance.domain_controller.id]
  }

  parameters = {
    DomainName         = var.domain_name
    SafeModePassword   = var.safe_mode_password
    NetBIOSName        = var.domain_netbios_name
    DatabasePath       = "C:\\NTDS"     # Single volume
    LogPath            = "C:\\Logs"     # Single volume  
    SysvolPath         = "C:\\SYSVOL"   # Single volume
  }

  depends_on = [aws_instance.domain_controller]
}

# SSM Document for Domain Configuration (Free Tier)
resource "aws_ssm_document" "domain_setup" {
  count           = var.enable_ssm ? 1 : 0
  name            = "${var.project_name}-${var.environment}-domain-setup"
  document_type   = "Command"
  document_format = "YAML"

  content = file("${path.module}/templates/domain_config_ssm.yml")

  tags = var.common_tags
}

# Output the instance ID for other modules
output "instance_id" {
  description = "Domain Controller instance ID"
  value       = aws_instance.domain_controller.id
}

output "private_ip" {
  description = "Domain Controller private IP"
  value       = aws_instance.domain_controller.private_ip
}

output "public_ip" {
  description = "Domain Controller public IP (if assigned)"
  value       = aws_instance.domain_controller.public_ip
}

output "security_group_id" {
  description = "Domain Controller security group ID"
  value       = aws_security_group.domain_controller.id
} 