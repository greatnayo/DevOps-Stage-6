terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Data source to get the existing VPC
data "aws_vpc" "existing" {
  id = var.vpc_id
}

# Data source to get available subnets in the VPC
data "aws_subnets" "available" {
  filter {
    name   = "vpc-id"
    values = [var.vpc_id]
  }
}

# Use provided subnet or select the first available
locals {
  subnet_id = var.subnet_id != "" ? var.subnet_id : data.aws_subnets.available.ids[0]
}

# Security Group for Application
resource "aws_security_group" "app" {
  name_prefix = "${var.project_name}-app-"
  description = "Security group for ${var.project_name} application"
  vpc_id      = var.vpc_id

  # HTTP
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Traefik API (dashboard)
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = var.ssh_allowed_cidr
  }

  # All outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-app-sg"
      Environment = var.environment
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# IAM Role for EC2 instance
resource "aws_iam_role" "app" {
  name_prefix = "${var.project_name}-"
  description = "IAM role for ${var.project_name} EC2 instance"

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

  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-app-role"
      Environment = var.environment
    }
  )
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "app" {
  name_prefix = "${var.project_name}-"
  role        = aws_iam_role.app.name
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_role_policy" "app_cloudwatch" {
  name_prefix = "${var.project_name}-cw-"
  role        = aws_iam_role.app.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:*:*"
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:DescribeTags"
        ]
        Resource = "*"
      }
    ]
  })
}

# Single EC2 Instance
resource "aws_instance" "app" {
  ami           = var.ami_id
  instance_type = var.instance_type
  subnet_id     = local.subnet_id
  key_name      = var.ssh_key_name != "" ? var.ssh_key_name : null

  iam_instance_profile = aws_iam_instance_profile.app.name
  security_groups      = [aws_security_group.app.id]

  associate_public_ip_address = true

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    environment  = var.environment
    project_name = var.project_name
  }))

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }

  monitoring = true

  tags = merge(
    var.tags,
    {
      Name        = var.instance_name
      Environment = var.environment
    }
  )

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = false

    tags = merge(
      var.tags,
      {
        Name = "${var.instance_name}-root"
      }
    )
  }

  depends_on = [aws_security_group.app]

  lifecycle {
    create_before_destroy = true
  }
}

# Elastic IP for the instance
resource "aws_eip" "app" {
  domain   = "vpc"
  instance = aws_instance.app.id
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.project_name}-eip"
      Environment = var.environment
    }
  )

  depends_on = [aws_instance.app]
}

# Local provisioner to generate Ansible inventory
resource "local_file" "ansible_inventory" {
  filename = "${path.module}/inventory/hosts.ini"

  content = templatefile("${path.module}/templates/inventory-single.tpl", {
    instance_ip        = aws_instance.app.private_ip
    instance_public_ip = aws_eip.app.public_ip
    instance_id        = aws_instance.app.id
    environment        = var.environment
    project_name       = var.project_name
    aws_region         = var.aws_region
  })

  depends_on = [aws_instance.app, aws_eip.app]
}

# Local provisioner to call Ansible
# Note: This is commented out as user_data script already handles ansible provisioning
# Uncomment if needed, but ensure passwordless sudo is configured on the host machine
# resource "null_resource" "ansible_provisioner" {
#   triggers = {
#     instance_id = aws_instance.app.id
#     public_ip   = aws_eip.app.public_ip
#   }
#
#   provisioner "local-exec" {
#     command = "cd ${path.module} && bash scripts/run_ansible_single.sh"
#
#     environment = {
#       ENVIRONMENT    = var.environment
#       PROJECT_NAME   = var.project_name
#       INSTANCE_IP    = aws_instance.app.private_ip
#       PUBLIC_IP      = aws_eip.app.public_ip
#       INSTANCE_ID    = aws_instance.app.id
#       AWS_REGION     = var.aws_region
#       INVENTORY_PATH = "${path.module}/inventory/hosts.ini"
#     }
#   }
#
#   depends_on = [local_file.ansible_inventory]
# }

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 7

  tags = merge(
    var.tags,
    {
      Environment = var.environment
    }
  )
}
