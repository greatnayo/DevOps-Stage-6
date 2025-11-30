# terraform/backend-config.hcl
# This file can be used to dynamically configure the S3 backend
# Usage: terraform init -backend-config=backend-config.hcl

bucket         = "nayo53-devops-stage-6-terraform-state"
key            = "infra/terraform.tfstate"
region         = "eu-west-2"
encrypt        = true
dynamodb_table = "terraform-locks"
