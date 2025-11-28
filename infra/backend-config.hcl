# terraform/backend-config.hcl
# This file can be used to dynamically configure the S3 backend
# Usage: terraform init -backend-config=backend-config.hcl

bucket         = "devops-stage-6-terraform-state"
key            = "infra/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-locks"
