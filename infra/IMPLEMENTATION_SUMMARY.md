# Infrastructure Setup Summary

This document summarizes the complete Infrastructure as Code setup for DevOps-Stage-6.

## What Has Been Created

### 1. Terraform Configuration (IaC)

**Location**: `infra/`

#### Core Files

- `main.tf` - Main infrastructure resources (20+)
- `variables.tf` - Input variables with validation
- `outputs.tf` - Output values for infrastructure details
- `backend.tf` - Remote state configuration (S3 + DynamoDB)
- `backend-config.hcl` - Backend configuration parameters

#### Features

✅ **Idempotent**: Re-running terraform does nothing unless changes exist
✅ **Fully Typed**: All variables have types and validation
✅ **Modular**: Clear separation of concerns
✅ **Documented**: Comments and descriptive names throughout

#### Resources Provisioned

- VPC with public/private subnets
- Internet Gateway & NAT Gateway
- Application Load Balancer with health checks
- Auto Scaling Group (min/max/desired capacity)
- Security Groups (ALB + App servers)
- EC2 Launch Template with IAM roles
- DynamoDB table for state locking

### 2. Ansible Configuration

**Location**: `infra/playbooks/`

#### Components

- `site.yml` - Main playbook for configuration management
- `roles/common/tasks/main.yml` - Common configuration tasks
- `templates/inventory.tpl` - Dynamic inventory template

#### Automation

✅ Automatically called after Terraform provisioning
✅ Installs Docker, Docker Compose, Python
✅ Configures CloudWatch monitoring
✅ Performs health checks
✅ Configurable via variables

### 3. CI/CD Drift Detection Pipeline

**Location**: `infra/.github/workflows/terraform-drift-detection.yml`

#### Workflow Features

✅ **Scheduled**: Runs every 6 hours automatically
✅ **Manual Trigger**: Can be run on demand
✅ **On Push**: Detects when `infra/` changes
✅ **Email Alerts**: Sends notifications when drift detected
✅ **Approval Required**: Pauses for manual review
✅ **Auto-Apply**: Only applies after approval
✅ **Safe**: Never modifies production without approval

#### Workflow Steps

1. Terraform plan (detect changes)
2. Analyze for drift
3. Email alert to team
4. Wait for manual approval (environment protection)
5. Apply changes (if approved)
6. Send confirmation email

### 4. Email Notification System

**Location**: `infra/scripts/send-email/`

#### Components

- `action.yml` - GitHub Action definition
- `entrypoint.sh` - Email sending script
- `send_via_ses.sh` - AWS SES integration
- `notify-drift.sh` - Local notification script

#### Email Features

✅ HTML formatted emails
✅ AWS SES integration
✅ Fallback to GitHub notifications
✅ Includes drift summary and planned changes
✅ Links to GitHub Actions workflow
✅ Environment details

### 5. Drift Detection Scripts

**Location**: `infra/scripts/`

#### Scripts

- `check-drift.sh` - Comprehensive drift detection
- `generate_inventory.sh` - Dynamic inventory from EC2
- `run_ansible.sh` - Post-provision Ansible execution
- `setup-backend.sh` - Initialize S3 + DynamoDB backend
- `notify-drift.sh` - Send email notifications

#### Features

✅ Can run locally or in CI/CD
✅ Auto-approve option for non-prod
✅ Detailed logging
✅ Error handling and recovery

### 6. Documentation

**Location**: `infra/`

#### Documents

- `README.md` - Complete infrastructure guide (500+ lines)
- `VARIABLES.md` - Variables reference with examples
- `QUICKSTART.md` - 5-minute quick start guide
- `DRIFT_DETECTION.md` - Drift detection setup and usage

#### Coverage

✅ Architecture overview with diagrams
✅ Prerequisite requirements
✅ Step-by-step setup instructions
✅ Common operations and troubleshooting
✅ Best practices and security considerations
✅ FAQ and support information

### 7. Helper Files

#### Makefile

- 40+ useful make targets
- Simplified commands for common tasks
- Color-coded output
- Examples included

#### Example Files

- `terraform.tfvars.example` - Example configuration
- `.gitignore` - Prevents committing sensitive files
- `user_data.sh` - EC2 bootstrap script

## How It Works

### Deployment Flow

```
1. Setup Backend
   └─> S3 bucket created (state storage)
   └─> DynamoDB table created (state locking)

2. Initialize Terraform
   └─> terraform init
   └─> Downloaded providers

3. Plan Infrastructure
   └─> terraform plan
   └─> 20+ resources to create

4. Deploy Infrastructure
   └─> terraform apply
   └─> Resources created in AWS
   └─> Inventory generated
   └─> Ansible runs automatically

5. Continuous Monitoring
   └─> Every 6 hours: Check for drift
   └─> If drift: Email alert + approval request
   └─> If approved: Auto-apply fixes
   └─> Send confirmation
```

### Drift Detection Flow

```
terraform plan
    ↓
Analysis
    ├─→ No changes → ✅ Success (no drift)
    └─→ Changes found → ⚠️ Drift detected
           ↓
       Email Alert
           ↓
       GitHub Issue Created
           ↓
       Wait for Approval
           ├─→ Approved → terraform apply
           └─→ Rejected → No changes
```

## File Structure

```
infra/
├── main.tf                          # Main resources
├── variables.tf                     # Input variables
├── outputs.tf                       # Output values
├── backend.tf                       # State backend
├── backend-config.hcl               # Backend params
├── user_data.sh                     # EC2 bootstrap
├── Makefile                         # Helper commands
├── .gitignore                       # Git ignore rules
│
├── templates/
│   └── inventory.tpl                # Ansible inventory
│
├── scripts/
│   ├── setup-backend.sh             # Initialize backend
│   ├── check-drift.sh               # Detect drift
│   ├── generate_inventory.sh        # Dynamic inventory
│   ├── run_ansible.sh               # Run Ansible
│   ├── notify-drift.sh              # Send notifications
│   ├── send_via_ses.sh              # AWS SES email
│   └── send-email/
│       ├── action.yml               # GitHub Action
│       └── entrypoint.sh
│
├── playbooks/
│   ├── site.yml                     # Main playbook
│   └── roles/
│       └── common/tasks/main.yml
│
├── inventory/
│   └── hosts.ini                    # Generated inventory
│
├── .github/workflows/
│   └── terraform-drift-detection.yml # CI/CD pipeline
│
└── [Documentation]
    ├── README.md                    # Full guide
    ├── VARIABLES.md                 # Variables reference
    ├── QUICKSTART.md                # Quick start
    ├── DRIFT_DETECTION.md           # Drift setup
    └── terraform.tfvars.example     # Example config
```

## Key Features

### 1. Idempotency

- Resources are only created once
- Changes detected and reported
- Manual approval prevents unwanted changes
- Safe to run repeatedly

### 2. State Management

- Remote state in S3 (secure)
- State locking via DynamoDB (prevents conflicts)
- Encrypted at rest (AES256)
- Versioning enabled (rollback capability)

### 3. Drift Detection

- Automatically detects infrastructure changes
- Runs on schedule (every 6 hours)
- Sends email alerts
- Requires approval before fixing
- Logs all changes

### 4. Security

- Security groups configured
- SSH access restricted (configurable)
- IAM roles with minimal permissions
- State bucket protected from public access
- Credentials in GitHub Secrets (not committed)

### 5. Scalability

- Auto Scaling Group for horizontal scaling
- Load balancer for traffic distribution
- Health checks for instance monitoring
- Configurable min/max/desired capacity

### 6. Monitoring

- CloudWatch integration in Ansible
- Health check endpoints
- Instance status tracking
- Drift detection alerts

## Getting Started

### Quick Start (5 minutes)

```bash
cd infra

# 1. Setup backend
bash scripts/setup-backend.sh

# 2. Initialize
terraform init -backend-config=backend-config.hcl

# 3. Plan
terraform plan

# 4. Deploy
terraform apply

# 5. Get outputs
terraform output
```

### Using Make (Easier)

```bash
cd infra

# View all available commands
make help

# Setup everything
make setup

# Deploy
make deploy

# Check for drift
make check-drift
```

## Next Steps

### 1. Customize Variables

```bash
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars
```

### 2. Configure Email Alerts (GitHub)

```bash
# Add secrets to GitHub
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# ALERT_EMAIL
```

### 3. Deploy Infrastructure

```bash
make deploy
```

### 4. Monitor Drift

```bash
# Automatic (CI/CD) - runs every 6 hours
# Or manual
make check-drift
```

### 5. Deploy Applications

Use Ansible to deploy services to EC2 instances

## Maintenance

### Regular Tasks

- Review drift alerts weekly
- Check infrastructure costs monthly
- Update Terraform providers quarterly
- Backup state files regularly
- Rotate AWS credentials periodically

### Emergency Recovery

```bash
# If stuck
make clean-locks

# Refresh state
make refresh-state

# Debug
make debug-plan
```

## Costs

### Estimated Monthly (dev environment)

- EC2 instances (2x t3.medium): ~$50-60
- ALB: ~$20
- NAT Gateway: ~$30
- Data transfer: ~$10
- **Total**: ~$100-150/month

### Cost Optimization

- Use `t3.micro` for dev (free tier eligible)
- Remove production resources when not needed
- Monitor CloudWatch costs

## Support

### Documentation

1. [README.md](./README.md) - Complete guide
2. [VARIABLES.md](./VARIABLES.md) - Configuration reference
3. [QUICKSTART.md](./QUICKSTART.md) - Fast setup
4. [DRIFT_DETECTION.md](./DRIFT_DETECTION.md) - Drift details

### Common Issues

See Troubleshooting section in README.md

### Debug

```bash
# Enable debug logging
TF_LOG=DEBUG terraform plan

# View logs
cat /var/log/user-data.log

# Check AWS resources
aws ec2 describe-instances
aws autoscaling describe-auto-scaling-groups
```

## Requirements Checklist

✅ **Terraform Configuration** - Complete idempotent setup
✅ **Remote Backend** - S3 + DynamoDB with locking
✅ **Dynamic Inventory** - Ansible inventory generated automatically
✅ **Ansible Integration** - Runs post-provisioning automatically
✅ **Drift Detection** - Scheduled every 6 hours
✅ **Email Alerts** - Sends drift notifications to configured address
✅ **Manual Approval** - Pauses before applying changes
✅ **Idempotency** - Safe to run terraform repeatedly
✅ **No Drift Auto-fix** - Only applies after approval
✅ **Full Documentation** - README, variables, quick start guides

## Validation

All requirements have been implemented:

1. ✅ Terraform provisions VPC, EC2, ALB, ASG, security groups
2. ✅ Remote backend configured with S3 and DynamoDB locking
3. ✅ Dynamic Ansible inventory generated from EC2 instances
4. ✅ Ansible called automatically after Terraform provisioning
5. ✅ Fully idempotent - resources only created once
6. ✅ Drift detection runs on schedule and on-demand
7. ✅ Email alerts sent when drift detected
8. ✅ Manual approval required before terraform apply
9. ✅ Automatic apply after approval (if no drift)
10. ✅ Safety, transparency, and full control maintained

---

**Setup Date**: 2025-11-28
**Terraform Version**: >= 1.0
**Status**: ✅ Ready for deployment

For more details, see the documentation files in this directory.
