# Infrastructure as Code - Terraform & Ansible

This directory contains the complete infrastructure setup for DevOps-Stage-6, including:

- **Terraform**: Infrastructure provisioning with idempotency and drift detection
- **Ansible**: Configuration management and application deployment
- **Single Command Deployment**: One-command full infrastructure provisioning and application deployment
- **CI/CD**: Automated drift detection with email alerts and approval workflow

## ⚡ Quick Start - Single Command Deployment

Deploy the entire infrastructure with a single command:

```bash
cd infra
terraform apply -auto-approve
```

This automatically:

1. Provisions AWS infrastructure (VPC, ALB, ASG, EC2)
2. Generates Ansible inventory from EC2 instances
3. Deploys applications via Ansible
4. Configures Traefik reverse proxy with SSL
5. Validates deployment health
6. Displays deployment summary

📖 **See:** [Single Command Deployment Guide](./SINGLE_COMMAND_DEPLOYMENT.md)
📋 **Quick Ref:** [Quick Reference](./SINGLE_COMMAND_QUICK_REFERENCE.md)
✅ **Checklist:** [Deployment Checklist](./DEPLOYMENT_CHECKLIST.md)

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Prerequisites](#prerequisites)
3. [Initial Setup](#initial-setup)
4. [Terraform Configuration](#terraform-configuration)
5. [Drift Detection & Email Alerts](#drift-detection--email-alerts)
6. [Manual Operations](#manual-operations)
7. [Troubleshooting](#troubleshooting)
8. [Best Practices](#best-practices)

## Architecture Overview

### Infrastructure Stack

```
┌─────────────────────────────────────────────────────────────┐
│                    AWS Infrastructure                       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Application Load Balancer                │  │
│  │              (Port 80 → 8080)                         │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                     │
│  ┌────────────────────┴─────────────────────────────────┐  │
│  │           Public Subnet (10.0.1.0/24)                │  │
│  │                                                       │  │
│  │  ┌──────────────┐    ┌──────────────┐               │  │
│  │  │  NAT Gateway │    │  IGW         │               │  │
│  │  └──────────────┘    └──────────────┘               │  │
│  └────────────────────┬─────────────────────────────────┘  │
│                       │                                     │
│  ┌────────────────────┴─────────────────────────────────┐  │
│  │         Private Subnet (10.0.2.0/24)                │  │
│  │                                                       │  │
│  │  ┌──────────────┐    ┌──────────────┐               │  │
│  │  │   App 1      │    │   App 2      │               │  │
│  │  │ (t3.medium)  │    │ (t3.medium)  │               │  │
│  │  └──────────────┘    └──────────────┘               │  │
│  │     (Auto-Scaling Group)                             │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### File Structure

```
infra/
├── main.tf                          # Main Terraform configuration
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── backend.tf                       # Remote state backend configuration
├── backend-config.hcl               # Backend configuration file
├── user_data.sh                     # EC2 bootstrap script
│
├── templates/
│   └── inventory.tpl                # Ansible inventory template
│
├── scripts/
│   ├── setup-backend.sh             # Initialize S3 & DynamoDB backend
│   ├── check-drift.sh               # Local drift detection script
│   ├── generate_inventory.sh        # Generate dynamic Ansible inventory
│   ├── run_ansible.sh               # Run Ansible after provisioning
│   ├── notify-drift.sh              # Send drift notifications
│   ├── send_via_ses.sh              # Send emails via AWS SES
│   └── send-email/                  # GitHub Action for email notifications
│       ├── action.yml
│       └── entrypoint.sh
│
├── playbooks/
│   ├── site.yml                     # Main Ansible playbook
│   └── roles/
│       └── common/
│           └── tasks/
│               └── main.yml         # Common configuration tasks
│
├── .github/workflows/
│   └── terraform-drift-detection.yml # CI/CD drift detection pipeline
│
├── inventory/
│   └── hosts.ini                    # Generated Ansible inventory (auto-created)
│
└── README.md                        # This file
```

## Prerequisites

### Local Requirements

- **Terraform**: >= 1.0 (`brew install terraform` or `apt install terraform`)
- **AWS CLI**: v2 (`brew install awscli` or download from AWS)
- **Ansible**: >= 2.9 (`pip install ansible`)
- **Python**: >= 3.8
- **Git**: Latest version

### AWS Requirements

- AWS Account with appropriate permissions
- AWS credentials configured locally: `aws configure`
- Required IAM permissions (see IAM Policy section)

### GitHub Requirements (for CI/CD)

- GitHub repository with workflow access
- GitHub Secrets configured:
  - `AWS_ACCESS_KEY_ID`
  - `AWS_SECRET_ACCESS_KEY`
  - `ALERT_EMAIL` (email for drift notifications)

## Initial Setup

### Step 1: Configure AWS Credentials

```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter default region (us-east-1)
# Enter default output format (json)
```

### Step 2: Set Up Remote Backend

The backend stores Terraform state in S3 with DynamoDB locking:

```bash
cd infra
bash scripts/setup-backend.sh
```

This script will:

- Create S3 bucket for state storage
- Enable versioning and encryption
- Block public access
- Create DynamoDB table for state locking

### Step 3: Initialize Terraform

```bash
cd infra
terraform init -backend-config=backend-config.hcl
```

### Step 4: Customize Variables

Edit `infra/terraform.tfvars` to customize your infrastructure:

```hcl
environment         = "dev"
project_name        = "devops-stage-6"
aws_region          = "us-east-1"
instance_type       = "t3.medium"
asg_min_size        = 1
asg_max_size        = 3
asg_desired_capacity = 2
ssh_allowed_cidr    = ["0.0.0.0/0"]  # Restrict this in production
```

## Terraform Configuration

### Core Resources

#### VPC & Networking

- VPC with configurable CIDR (default: 10.0.0.0/16)
- Public Subnet for NAT Gateway and ALB
- Private Subnet for application servers
- NAT Gateway for outbound internet access
- Internet Gateway for ingress traffic

#### Security

- Security Group for ALB (ports 80, 443)
- Security Group for app servers (internal communication + SSH)
- Network ACLs for granular control

#### Load Balancing

- Application Load Balancer
- Target Group with health checks (GET /health, 200 OK)
- HTTP listener (port 80)

#### Compute

- Launch Template for EC2 instances
- Auto Scaling Group (min/max/desired capacity)
- IAM Role for EC2 instances with S3 access
- Instance Profile for role assignment

### Key Features

#### 1. Idempotency

Terraform is fully idempotent:

```bash
# First run - creates resources
terraform apply

# Second run - no changes (unless drift detected)
terraform plan
# Output: No changes. Infrastructure is up-to-date.

# If you change a variable, Terraform only updates affected resources
# Resources with no changes are left untouched
```

#### 2. State Management

State is stored remotely in S3 with locking:

```bash
# View current state
terraform state list

# Show specific resource
terraform state show aws_vpc.main

# Lock is automatically managed during apply
# Multiple users can safely work on the same infrastructure
```

#### 3. Outputs

Access infrastructure details:

```bash
# Show all outputs
terraform output

# Get specific output
terraform output alb_dns_name

# Save outputs to file
terraform output -json > outputs.json
```

### Common Operations

#### View Plan Before Applying

```bash
cd infra
terraform plan
# Review the changes carefully
terraform apply  # or: terraform apply tfplan
```

#### Scale Auto Scaling Group

```bash
# Change desired capacity
terraform apply -var='asg_desired_capacity=5'
```

#### Destroy Infrastructure (⚠️ Careful!)

```bash
cd infra
terraform destroy
# Review what will be deleted
# Type 'yes' to confirm
```

#### Import Existing Resources

```bash
# If you have existing AWS resources
terraform import aws_vpc.main vpc-12345678
```

## Drift Detection & Email Alerts

### What is Drift?

Drift occurs when your actual infrastructure differs from your Terraform configuration. This can happen if:

- Manual changes are made to AWS resources
- Other tools modify your infrastructure
- Infrastructure failures occur and resources are replaced

### Drift Detection Workflow

```
┌─────────────────────────────────────────────────────────┐
│          Scheduled or Manual Trigger (GitHub Actions)   │
└────────────────────┬────────────────────────────────────┘
                     │
        ┌────────────▼─────────────┐
        │  Run terraform plan      │
        │  (6-hour schedule)       │
        └────────────┬─────────────┘
                     │
        ┌────────────▼──────────────────────────┐
        │  Detect Changes                       │
        │  - No changes → ✅ Success, Exit      │
        │  - Changes found → ⚠️ Drift detected  │
        └────────────┬──────────────────────────┘
                     │
        ┌────────────▼────────────────────┐
        │  Send Email to Alert Address    │
        │  Create GitHub Issue for Review │
        └────────────┬────────────────────┘
                     │
        ┌────────────▼────────────────────┐
        │  Wait for Manual Approval       │
        │  (Environment protection rule)  │
        └────────────┬────────────────────┘
                     │
        ┌────────────▼────────────────────┐
        │  Human Reviews Changes          │
        │  Approves or Rejects in GitHub  │
        └────────────┬────────────────────┘
                     │
        ┌────────────▼────────────────────┐
        │  If Approved:                   │
        │  terraform apply (auto)         │
        │  Send confirmation email        │
        └────────────┴────────────────────┘
```

### Email Notifications

#### Drift Detection Email

When drift is detected, you'll receive:

- **Subject**: 🚨 Infrastructure Drift Detected - Manual Approval Required
- **Content**:
  - Summary of changes
  - Terraform plan output
  - Link to GitHub Actions workflow
  - Action button to review and approve
  - Environment details (region, project, etc.)

#### Manual Approval

1. Email arrives with drift notification
2. Click "Review in GitHub" link
3. GitHub issue shows planned changes
4. Approve by clicking "✅ Approve" in GitHub
5. `terraform apply` runs automatically
6. Confirmation email is sent

### GitHub Actions Workflow

#### Setup GitHub Secrets

1. Go to repository Settings → Secrets and variables
2. Add these secrets:
   - `AWS_ACCESS_KEY_ID`: Your AWS access key
   - `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
   - `ALERT_EMAIL`: Email address for drift alerts

#### Workflow File

Located at: `.github/workflows/terraform-drift-detection.yml`

**Triggers**:

- Scheduled: Every 6 hours (0 _/6 _ \* \*)
- Manual: Via GitHub Actions UI
- On push: When `infra/**` changes

**Jobs**:

1. `terraform-plan`: Run plan and detect drift
2. `send-drift-notification`: Email alert (if drift detected)
3. `request-approval`: Wait for manual approval
4. `terraform-apply`: Apply approved changes
5. `auto-apply-no-drift`: Auto-apply if no drift

#### Manual Trigger

```bash
# Trigger workflow from command line
gh workflow run terraform-drift-detection.yml -f approve=yes

# Or via GitHub UI:
# 1. Go to Actions tab
# 2. Select "Terraform Drift Detection & Deployment"
# 3. Click "Run workflow"
# 4. Set approve=yes (optional)
```

### Local Drift Detection

Run drift detection without CI/CD:

```bash
cd infra

# Check for drift
bash scripts/check-drift.sh

# Check for drift and auto-approve changes
bash scripts/check-drift.sh --auto-approve

# Send drift notification
bash scripts/notify-drift.sh your-email@example.com detected
```

## Manual Operations

### Provisioning Infrastructure

#### 1. Plan

```bash
cd infra
terraform plan
```

Review the output carefully. It should show:

- Resources to be created
- Resources to be modified
- Resources to be destroyed

#### 2. Apply

```bash
terraform apply
```

Or with a saved plan:

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

#### 3. Verify

```bash
# Check outputs
terraform output

# Get ALB DNS name to access your application
terraform output alb_dns_name

# Test application health
curl http://$(terraform output -raw alb_dns_name)/health
```

### Running Ansible After Terraform

Ansible is automatically run via the `null_resource` provisioner in Terraform:

```bash
# Manually run Ansible
cd infra
bash scripts/run_ansible.sh

# Or with environment variables
export ENVIRONMENT=dev
export PROJECT_NAME=devops-stage-6
bash scripts/run_ansible.sh
```

### Updating Infrastructure

#### Change Variable Value

```bash
# Update and apply
terraform apply -var='asg_desired_capacity=5'

# Or edit tfvars file and run
terraform apply -var-file=terraform.tfvars
```

#### Modify Configuration File

```bash
# Edit main.tf
vim main.tf

# Plan and apply
terraform plan
terraform apply
```

#### Destroy Specific Resource

```bash
# Destroy and recreate
terraform destroy -target aws_autoscaling_group.app
terraform apply -target aws_autoscaling_group.app
```

## Troubleshooting

### Terraform Issues

#### Error: Backend Configuration Has Changed

```
Error: Backend configuration has changed
```

**Solution**:

```bash
rm -rf .terraform
terraform init -backend-config=backend-config.hcl
```

#### Error: State Lock

```
Error: Error acquiring the state lock
```

**Solution**:

```bash
# Force unlock (use with caution!)
terraform force-unlock LOCK_ID
```

#### Error: Invalid AWS Credentials

```
Error: error configuring Terraform AWS Provider
```

**Solution**:

```bash
aws configure
# Or set environment variables
export AWS_ACCESS_KEY_ID=xxx
export AWS_SECRET_ACCESS_KEY=xxx
```

### Ansible Issues

#### Hosts Not Found

```bash
# Check inventory
cat inventory/hosts.ini

# Regenerate
bash scripts/generate_inventory.sh
```

#### SSH Connection Failed

```bash
# Check SSH key
ls -la ~/.ssh/id_rsa

# Add to SSH agent
ssh-add ~/.ssh/id_rsa

# Test connection
ssh -v ec2-user@<instance-ip>
```

#### Playbook Failed

```bash
# Run with verbose output
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -vvv
```

### AWS Issues

#### EC2 Instance Not Ready

```bash
# Check instance status
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]'

# Check user data log
aws ssm start-session --target <instance-id>
cat /var/log/user-data.log
```

#### ALB Not Routing Traffic

```bash
# Check target health
aws elbv2 describe-target-health --target-group-arn <tg-arn>

# Check security groups
aws ec2 describe-security-groups --group-ids <sg-id>
```

## Best Practices

### 1. Always Plan Before Apply

```bash
terraform plan
# Review output carefully
terraform apply
```

### 2. Use Variables for Configuration

❌ **Don't**: Hardcode values in main.tf

```hcl
instance_type = "t3.medium"  # BAD
```

✅ **Do**: Use variables

```hcl
instance_type = var.instance_type  # GOOD
```

### 3. Secure Sensitive Data

❌ **Don't**: Commit secrets to Git

```bash
git add terraform.tfvars  # BAD if it contains secrets
```

✅ **Do**: Use `.gitignore` and environment variables

```bash
echo "terraform.tfvars" >> .gitignore
export TF_VAR_db_password="secret"
```

### 4. State Management

- ✅ Store state remotely (S3)
- ✅ Enable state locking (DynamoDB)
- ✅ Enable encryption
- ❌ Don't commit state files to Git
- ❌ Don't edit state manually

### 5. Code Organization

```
✅ GOOD:
infra/
├── main.tf        # Main resources
├── variables.tf   # Input variables
├── outputs.tf     # Output values
└── terraform.tfvars

❌ BAD:
everything.tf      # All code in one file
```

### 6. Testing

```bash
# Format check
terraform fmt -check -recursive

# Syntax validation
terraform validate

# Plan review
terraform plan -json | jq .

# Staging environment test
terraform apply -target aws_lb.main
```

### 7. Monitoring & Alerts

- ✅ Enable CloudWatch monitoring
- ✅ Set up drift detection
- ✅ Configure email alerts
- ✅ Review logs regularly

### 8. Documentation

- ✅ Document all variables
- ✅ Explain resource relationships
- ✅ Provide examples
- ✅ Keep README updated

### 9. Team Collaboration

- ✅ Use environment protection rules
- ✅ Require approval for production changes
- ✅ Enable audit logging
- ✅ Tag all resources

### 10. Disaster Recovery

```bash
# Backup state
aws s3 sync s3://devops-stage-6-terraform-state ./state-backup

# Keep state version history enabled
# DynamoDB backup enabled

# Document recovery procedures
```

## Security Considerations

### IAM Permissions

Minimum required IAM policy:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "elasticloadbalancing:*",
        "autoscaling:*",
        "iam:*",
        "s3:GetObject",
        "s3:ListBucket",
        "dynamodb:PutItem",
        "dynamodb:GetItem",
        "dynamodb:DeleteItem"
      ],
      "Resource": "*"
    }
  ]
}
```

### SSH Access

Restrict SSH access to known IPs:

```hcl
ssh_allowed_cidr = ["203.0.113.0/32"]  # Your IP
```

### Secrets Management

Use AWS Secrets Manager for sensitive data:

```hcl
data "aws_secretsmanager_secret_version" "db_password" {
  secret_id = "rds/db_password"
}
```

## Additional Resources

- [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)
- [Best Practices for Terraform](https://www.terraform.io/docs/cloud/guides/recommended-practices)

## Support

For issues or questions:

1. Check the Troubleshooting section
2. Review Terraform logs: `TF_LOG=DEBUG terraform plan`
3. Check AWS CloudTrail for API errors
4. Review Ansible logs: `ansible-playbook -vvv`

## License

This infrastructure code is part of DevOps-Stage-6 project.

---

**Last Updated**: 2025-11-28
**Terraform Version**: >= 1.0
**AWS Region**: us-east-1
