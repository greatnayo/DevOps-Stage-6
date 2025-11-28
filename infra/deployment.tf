# deployment.tf - Orchestrates the entire deployment pipeline
# This module coordinates infrastructure provisioning, inventory generation,
# Ansible execution, and Traefik/SSL configuration for a single-command deployment

locals {
  deployment_id = "${var.project_name}-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  inventory_dir = "${path.module}/inventory"
  
  # Deployment stages
  stage_1_infrastructure = "provisioned"
  stage_2_inventory      = "inventory_ready"
  stage_3_ansible        = "ansible_deployed"
  stage_4_traefik        = "traefik_configured"
}

# ==============================================================================
# Stage 1: Ensure Infrastructure is Provisioned (already done by main.tf)
# ==============================================================================
# This is implicit - the resources in main.tf are dependencies

# ==============================================================================
# Stage 2: Generate Ansible Inventory from EC2 Instances
# ==============================================================================

# Create inventory directory
resource "null_resource" "create_inventory_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${local.inventory_dir}"
  }
}

# Generate dynamic inventory from ASG/target group
resource "local_file" "ansible_inventory_dynamic" {
  filename = "${local.inventory_dir}/hosts.ini"

  content = templatefile("${path.module}/templates/inventory.tpl", {
    asg_name           = aws_autoscaling_group.app.name
    target_group_arn   = aws_lb_target_group.main.arn
    alb_dns_name       = aws_lb.main.dns_name
    environment        = var.environment
    project_name       = var.project_name
    region             = var.aws_region
  })

  depends_on = [
    aws_autoscaling_group.app,
    aws_lb.main,
    null_resource.create_inventory_dir
  ]
}

# ==============================================================================
# Stage 3: Run Ansible Provisioner
# ==============================================================================

# Wait for instances to be healthy
resource "null_resource" "wait_for_instances" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/wait_for_instances.sh"
    
    environment = {
      TARGET_GROUP_ARN = aws_lb_target_group.main.arn
      AWS_REGION       = var.aws_region
      TIMEOUT          = var.instance_ready_timeout
    }
  }

  depends_on = [
    aws_autoscaling_group.app,
    local_file.ansible_inventory_dynamic
  ]
}

# Run Ansible playbook for application deployment
resource "null_resource" "ansible_deploy" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/run_ansible_full.sh"
    
    environment = {
      ENVIRONMENT       = var.environment
      PROJECT_NAME      = var.project_name
      ALB_DNS_NAME      = aws_lb.main.dns_name
      INVENTORY_PATH    = local_file.ansible_inventory_dynamic.filename
      PLAYBOOK_DIR      = "${path.module}/playbooks"
      AWS_REGION        = var.aws_region
      TARGET_GROUP_ARN  = aws_lb_target_group.main.arn
    }
  }

  triggers = {
    asg_id         = aws_autoscaling_group.app.id
    inventory_hash = local_file.ansible_inventory_dynamic.id
  }

  depends_on = [null_resource.wait_for_instances]
}

# ==============================================================================
# Stage 4: Configure Traefik and SSL
# ==============================================================================

# Generate Traefik configuration
resource "local_file" "traefik_config" {
  filename = "${path.module}/traefik/traefik.yml"

  content = templatefile("${path.module}/templates/traefik-config.tpl", {
    acme_email       = var.traefik_acme_email
    environment      = var.environment
    project_name     = var.project_name
    alb_dns_name     = aws_lb.main.dns_name
    dashboard_domain = var.traefik_dashboard_domain
    enable_ssl       = var.enable_ssl
    ssl_provider     = var.ssl_provider
  })

  depends_on = [aws_lb.main]
}

# Deploy Traefik configuration via Ansible
resource "null_resource" "ansible_traefik" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/deploy_traefik.sh"
    
    environment = {
      ENVIRONMENT      = var.environment
      PROJECT_NAME     = var.project_name
      INVENTORY_PATH   = local_file.ansible_inventory_dynamic.filename
      TRAEFIK_CONFIG   = local_file.traefik_config.filename
      PLAYBOOK_DIR     = "${path.module}/playbooks"
      ENABLE_SSL       = var.enable_ssl
      SSL_PROVIDER     = var.ssl_provider
      ACME_EMAIL       = var.traefik_acme_email
    }
  }

  triggers = {
    traefik_config_hash = local_file.traefik_config.id
    ansible_deploy      = null_resource.ansible_deploy.id
  }

  depends_on = [
    null_resource.ansible_deploy,
    local_file.traefik_config
  ]
}

# ==============================================================================
# Stage 5: Health Checks and Validation
# ==============================================================================

# Validate deployment
resource "null_resource" "validate_deployment" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/validate_deployment.sh"
    
    environment = {
      ALB_DNS_NAME      = aws_lb.main.dns_name
      HEALTH_CHECK_URL  = "/health"
      MAX_RETRIES       = "30"
      RETRY_INTERVAL    = "10"
      ENVIRONMENT       = var.environment
      PROJECT_NAME      = var.project_name
    }
  }

  depends_on = [null_resource.ansible_traefik]
}

# ==============================================================================
# Deployment Summary Output
# ==============================================================================

resource "null_resource" "deployment_summary" {
  provisioner "local-exec" {
    command = "bash ${path.module}/scripts/deployment_summary.sh"
    
    environment = {
      DEPLOYMENT_ID    = local.deployment_id
      ALB_DNS_NAME     = aws_lb.main.dns_name
      ENVIRONMENT      = var.environment
      PROJECT_NAME     = var.project_name
      INVENTORY_FILE   = local_file.ansible_inventory_dynamic.filename
      ENABLE_SSL       = var.enable_ssl
      TRAEFIK_DASHBOARD = var.traefik_dashboard_domain
    }
  }

  depends_on = [null_resource.validate_deployment]
}
