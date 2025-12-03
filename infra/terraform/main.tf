terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
}


resource "aws_security_group" "todo_app" {
  name        = "devops-app-sg"
  description = "Security group for TODO application"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    from_port   = 3600
    to_port     = 3600
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "devops-app-sg"
  }
}

# SSH Key
resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = file(pathexpand(var.public_key_path))
}


# EC2 Instance
resource "aws_instance" "todo_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.todo_app.id]

  root_block_device {
    volume_size = 30
  }

  tags = {
    Name = "devops-app-server"
    description = "EC2 instance for TODO application"
  }

  depends_on = [aws_security_group.todo_app]
}

# Elastic IP 
resource "aws_eip" "todo_server" {
  instance = aws_instance.todo_server.id
  domain   = "vpc"

  provisioner "remote-exec" {
    inline = ["echo 'Instance is ready'"]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(pathexpand(var.private_key_path))
      host        = self.public_ip
      timeout     = "5m"
    }
  }

  depends_on = [aws_instance.todo_server]
}

# Ansible Inventory 
resource "local_file" "ansible_inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    server_ip        = aws_eip.todo_server.public_ip
    server_user      = "ubuntu"
    private_key_path = var.private_key_path
  })
  filename = "${path.module}/../ansible/inventory/hosts.ini"
  depends_on = [aws_eip.todo_server]
}

# Run Ansible Playbook
resource "null_resource" "ansible_provisioner" {
  provisioner "local-exec" {
    command = "cd ${path.module}/../ansible && ansible-playbook -i inventory/hosts.ini playbook.yml"
    environment = {
      ANSIBLE_HOST_KEY_CHECKING = "False"
    }
  }

  depends_on = [local_file.ansible_inventory, aws_instance.todo_server, aws_eip.todo_server]
}
