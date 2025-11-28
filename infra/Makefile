.PHONY: help init plan apply destroy fmt validate check-drift drift-notify setup-backend clean list-state

# Colors for output
RED := \033[0;31m
GREEN := \033[0;32m
YELLOW := \033[0;33m
BLUE := \033[0;34m
NC := \033[0m # No Color

# Default target
help:
	@echo "$(BLUE)===================================$(NC)"
	@echo "$(BLUE)Terraform Infrastructure Management$(NC)"
	@echo "$(BLUE)===================================$(NC)"
	@echo ""
	@echo "$(GREEN)Setup & Initialization:$(NC)"
	@echo "  make setup-backend      Setup S3 & DynamoDB for remote state"
	@echo "  make init               Initialize Terraform"
	@echo "  make validate           Validate Terraform configuration"
	@echo "  make fmt                Format Terraform code"
	@echo ""
	@echo "$(GREEN)Planning & Deployment:$(NC)"
	@echo "  make plan               Show what will be created/modified"
	@echo "  make apply              Deploy infrastructure"
	@echo "  make destroy            Destroy all infrastructure (⚠️  Careful!)"
	@echo ""
	@echo "$(GREEN)Drift Detection:$(NC)"
	@echo "  make check-drift        Check for infrastructure drift"
	@echo "  make check-drift-auto   Check and auto-apply drift fixes"
	@echo "  make drift-notify       Send drift notification email"
	@echo ""
	@echo "$(GREEN)State Management:$(NC)"
	@echo "  make list-state         List all resources in state"
	@echo "  make refresh-state      Refresh state from AWS"
	@echo "  make outputs            Show Terraform outputs"
	@echo ""
	@echo "$(GREEN)Cleanup:$(NC)"
	@echo "  make clean              Remove local Terraform files"
	@echo "  make clean-locks        Remove state locks (if stuck)"
	@echo ""
	@echo "$(GREEN)Ansible:$(NC)"
	@echo "  make gen-inventory      Generate Ansible inventory"
	@echo "  make run-ansible        Run Ansible playbooks"
	@echo ""
	@echo "$(YELLOW)Examples:$(NC)"
	@echo "  make plan               # See what will happen"
	@echo "  make apply              # Deploy infrastructure"
	@echo "  make check-drift        # Check for drift"

# Setup & Initialization Targets

setup-backend:
	@echo "$(BLUE)Setting up Terraform backend...$(NC)"
	@bash scripts/setup-backend.sh
	@echo "$(GREEN)✅ Backend setup complete$(NC)"

init:
	@echo "$(BLUE)Initializing Terraform...$(NC)"
	@terraform init -backend-config=backend-config.hcl -upgrade
	@echo "$(GREEN)✅ Terraform initialized$(NC)"

validate:
	@echo "$(BLUE)Validating Terraform configuration...$(NC)"
	@terraform validate
	@echo "$(GREEN)✅ Validation passed$(NC)"

fmt:
	@echo "$(BLUE)Formatting Terraform code...$(NC)"
	@terraform fmt -recursive
	@echo "$(GREEN)✅ Formatting complete$(NC)"

fmt-check:
	@echo "$(BLUE)Checking Terraform format...$(NC)"
	@terraform fmt -check -recursive
	@echo "$(GREEN)✅ Format check passed$(NC)"

# Planning & Deployment Targets

plan:
	@echo "$(BLUE)Creating Terraform plan...$(NC)"
	@terraform plan -out=tfplan
	@echo "$(GREEN)✅ Plan created (tfplan)$(NC)"

plan-json:
	@echo "$(BLUE)Creating Terraform plan (JSON)...$(NC)"
	@terraform plan -json > tfplan.json
	@echo "$(GREEN)✅ Plan created (tfplan.json)$(NC)"

apply:
	@echo "$(BLUE)Applying Terraform configuration...$(NC)"
	@if [ -f tfplan ]; then \
		terraform apply tfplan; \
	else \
		terraform apply; \
	fi
	@echo "$(GREEN)✅ Apply complete$(NC)"

apply-auto:
	@echo "$(BLUE)Applying Terraform (auto-approve)...$(NC)"
	@terraform apply -auto-approve
	@echo "$(GREEN)✅ Apply complete$(NC)"

destroy:
	@echo "$(RED)⚠️  This will DESTROY all infrastructure!$(NC)"
	@echo "Press Ctrl+C to cancel, or continue..."
	@sleep 3
	@terraform destroy

destroy-auto:
	@echo "$(RED)⚠️  Destroying infrastructure...$(NC)"
	@terraform destroy -auto-approve
	@echo "$(GREEN)✅ Destroy complete$(NC)"

# Drift Detection Targets

check-drift:
	@echo "$(BLUE)Checking for infrastructure drift...$(NC)"
	@bash scripts/check-drift.sh
	@echo "$(GREEN)✅ Drift check complete$(NC)"

check-drift-auto:
	@echo "$(BLUE)Checking for drift and auto-applying...$(NC)"
	@bash scripts/check-drift.sh --auto-approve
	@echo "$(GREEN)✅ Drift check complete$(NC)"

drift-notify:
	@echo "$(BLUE)Sending drift notification...$(NC)"
	@bash scripts/notify-drift.sh ${EMAIL} detected
	@echo "$(GREEN)✅ Notification sent$(NC)"

# State Management Targets

list-state:
	@echo "$(BLUE)Terraform State Resources:$(NC)"
	@terraform state list
	@echo ""

show-state:
	@echo "$(BLUE)Terraform State:$(NC)"
	@terraform state show ${RESOURCE}

refresh-state:
	@echo "$(BLUE)Refreshing state from AWS...$(NC)"
	@terraform refresh
	@echo "$(GREEN)✅ State refreshed$(NC)"

outputs:
	@echo "$(BLUE)Terraform Outputs:$(NC)"
	@terraform output
	@echo ""

outputs-json:
	@echo "$(BLUE)Terraform Outputs (JSON):$(NC)"
	@terraform output -json
	@echo ""

# Ansible Targets

gen-inventory:
	@echo "$(BLUE)Generating Ansible inventory...$(NC)"
	@bash scripts/generate_inventory.sh
	@echo "$(GREEN)✅ Inventory generated$(NC)"
	@cat inventory/hosts.ini

run-ansible:
	@echo "$(BLUE)Running Ansible playbooks...$(NC)"
	@bash scripts/run_ansible.sh
	@echo "$(GREEN)✅ Ansible execution complete$(NC)"

ping-hosts:
	@echo "$(BLUE)Testing Ansible host connectivity...$(NC)"
	@ansible all -i inventory/hosts.ini -m ping

# Cleanup Targets

clean:
	@echo "$(YELLOW)Cleaning local Terraform files...$(NC)"
	@rm -rf .terraform terraform.tfstate* tfplan* tfplan.json
	@echo "$(GREEN)✅ Cleanup complete$(NC)"

clean-locks:
	@echo "$(YELLOW)Removing state locks...$(NC)"
	@aws dynamodb scan --table-name terraform-locks --region us-east-1 \
		--query 'Items[].LockID.S' --output text | \
		xargs -I {} aws dynamodb delete-item --table-name terraform-locks \
		--key '{"LockID":{"S":"{}"}}'  --region us-east-1
	@echo "$(GREEN)✅ Locks removed$(NC)"

# Utility Targets

logs:
	@echo "$(BLUE)Recent Terraform logs:$(NC)"
	@tail -50 /var/log/user-data.log 2>/dev/null || echo "Logs not available locally"

debug-plan:
	@echo "$(BLUE)Running plan with debug output...$(NC)"
	@TF_LOG=DEBUG terraform plan

debug-apply:
	@echo "$(BLUE)Running apply with debug output...$(NC)"
	@TF_LOG=DEBUG terraform apply

# Composite Targets

setup: setup-backend init validate fmt
	@echo "$(GREEN)✅ Full setup complete$(NC)"

deploy: validate fmt plan apply
	@echo "$(GREEN)✅ Deployment complete$(NC)"

deploy-auto: validate fmt apply-auto
	@echo "$(GREEN)✅ Deployment complete (auto-approved)$(NC)"

full-check: fmt-check validate plan
	@echo "$(GREEN)✅ Full check passed$(NC)"

# AWS CLI Helpers

show-instances:
	@echo "$(BLUE)EC2 Instances:$(NC)"
	@aws ec2 describe-instances \
		--filters "Name=tag:Environment,Values=dev" \
		--query 'Reservations[].Instances[].[InstanceId,State.Name,InstanceType,PrivateIpAddress]' \
		--output table

show-asg:
	@echo "$(BLUE)Auto Scaling Groups:$(NC)"
	@aws autoscaling describe-auto-scaling-groups \
		--query 'AutoScalingGroups[?Tags[?Key==`Name` && Value==`devops-stage-6-asg`]].[AutoScalingGroupName,MinSize,MaxSize,DesiredCapacity]' \
		--output table

show-alb:
	@echo "$(BLUE)Load Balancer DNS:$(NC)"
	@terraform output -raw alb_dns_name
	@echo ""

show-sg:
	@echo "$(BLUE)Security Groups:$(NC)"
	@aws ec2 describe-security-groups \
		--filters "Name=tag:Project,Values=devops-stage-6" \
		--query 'SecurityGroups[].[GroupId,GroupName]' \
		--output table

# Cost Estimation

estimate-cost:
	@echo "$(BLUE)Estimated Monthly Cost:$(NC)"
	@echo "$(YELLOW)t3.medium (default):$(NC) ~\$$40-60/month per instance"
	@echo "$(YELLOW)ALB:$(NC) ~\$$20/month"
	@echo "$(YELLOW)Data transfer:$(NC) ~\$$5-15/month"
	@echo "$(YELLOW)$(BLUE)Total (2 instances):$(NC) ~\$$100-150/month"
	@echo ""
	@echo "$(GREEN)Use 't3.micro' for free tier (if eligible)$(NC)"

# Documentation

docs:
	@echo "$(BLUE)Opening documentation...$(NC)"
	@echo "Main guide: $(BLUE)README.md$(NC)"
	@echo "Variables: $(BLUE)VARIABLES.md$(NC)"
	@echo "Drift detection: $(BLUE)DRIFT_DETECTION.md$(NC)"
	@echo "Quick start: $(BLUE)QUICKSTART.md$(NC)"

# Version info

info:
	@echo "$(BLUE)Environment Information:$(NC)"
	@echo "Terraform: $$(terraform version -json | jq -r '.terraform_version')"
	@echo "AWS CLI: $$(aws --version)"
	@echo "Ansible: $$(ansible --version | head -1)"
	@echo "$(BLUE)Configured Region:$(NC) $$(aws configure get region)"
	@echo "$(BLUE)AWS Account:$(NC) $$(aws sts get-caller-identity --query Account --output text)"
	@echo ""

# Default if no target specified
.DEFAULT_GOAL := help
