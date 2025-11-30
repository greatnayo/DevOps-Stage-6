variable "aws_region" {
  description = "AWS region for infrastructure"
  type        = string
  default     = "eu-west-2"
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "devops-stage-6"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be one of: dev, staging, prod"
  }
}

# Existing VPC Configuration
variable "vpc_id" {
  description = "Existing VPC ID to use for deployment"
  type        = string
  default     = "vpc-0bc57eb51ad568c41"
}

variable "vpc_cidr" {
  description = "CIDR block of existing VPC (for reference)"
  type        = string
  default     = "172.31.0.0/16"
}

variable "subnet_id" {
  description = "Existing subnet ID for EC2 instance"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^subnet-", var.subnet_id)) || var.subnet_id == ""
    error_message = "Subnet ID must start with 'subnet-' or be empty"
  }
}

variable "ami_id" {
  description = "AMI ID for EC2 instance"
  type        = string
  default     = "ami-03f3a22c5f8f5ef58" # Amazon Linux 2 in eu-west-2

  validation {
    condition     = can(regex("^ami-", var.ami_id))
    error_message = "AMI ID must start with 'ami-'"
  }
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro"

  validation {
    condition     = can(regex("^t[2-4]\\.", var.instance_type)) || can(regex("^m[5-7]\\.", var.instance_type))
    error_message = "Instance type must be a t2/t3/t4 or m5/m6/m7 type"
  }
}

variable "instance_name" {
  description = "Name tag for the EC2 instance"
  type        = string
  default     = "devops-stage-6-app"
}

variable "ssh_allowed_cidr" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"] # Change this to restrict SSH access

  validation {
    condition     = length(var.ssh_allowed_cidr) > 0
    error_message = "At least one CIDR block must be specified"
  }
}

variable "ssh_key_name" {
  description = "EC2 key pair name for SSH access"
  type        = string
  default     = ""
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    ManagedBy   = "terraform"
    CreatedDate = "2025-11-30"
  }
}

# ==============================================================================
# Deployment Configuration Variables
# ==============================================================================

variable "instance_ready_timeout" {
  description = "Timeout (in seconds) to wait for instances to be ready"
  type        = number
  default     = 300

  validation {
    condition     = var.instance_ready_timeout > 0
    error_message = "Timeout must be greater than 0"
  }
}

variable "ansible_execution_timeout" {
  description = "Timeout (in seconds) for Ansible playbook execution"
  type        = number
  default     = 600

  validation {
    condition     = var.ansible_execution_timeout > 0
    error_message = "Timeout must be greater than 0"
  }
}

variable "enable_ssl" {
  description = "Enable SSL/TLS for Traefik"
  type        = bool
  default     = true
}

variable "ssl_provider" {
  description = "SSL certificate provider (letsencrypt, acm)"
  type        = string
  default     = "letsencrypt"

  validation {
    condition     = contains(["letsencrypt", "acm"], var.ssl_provider)
    error_message = "SSL provider must be 'letsencrypt' or 'acm'"
  }
}

variable "traefik_acme_email" {
  description = "Email for ACME provider (Let's Encrypt)"
  type        = string
  default     = "admin@example.com"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$", var.traefik_acme_email))
    error_message = "Must be a valid email address"
  }
}

variable "traefik_dashboard_domain" {
  description = "Domain for Traefik dashboard"
  type        = string
  default     = "traefik.example.com"
}

variable "enable_deployment_validation" {
  description = "Enable post-deployment health checks"
  type        = bool
  default     = true
}

variable "deployment_health_check_interval" {
  description = "Health check interval in seconds"
  type        = number
  default     = 10

  validation {
    condition     = var.deployment_health_check_interval > 0
    error_message = "Interval must be greater than 0"
  }
}

variable "deployment_health_check_retries" {
  description = "Number of health check retries"
  type        = number
  default     = 30

  validation {
    condition     = var.deployment_health_check_retries > 0
    error_message = "Retries must be greater than 0"
  }
}

variable "idempotent_deployment" {
  description = "Enable idempotent deployment (skip unchanged resources)"
  type        = bool
  default     = true
}

variable "deployment_log_level" {
  description = "Deployment script log level (debug, info, warn, error)"
  type        = string
  default     = "info"

  validation {
    condition     = contains(["debug", "info", "warn", "error"], var.deployment_log_level)
    error_message = "Log level must be 'debug', 'info', 'warn', or 'error'"
  }
}

