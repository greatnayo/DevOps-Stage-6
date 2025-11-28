# Terraform Quick Reference Card

## Setup (First Time)

```bash
cd infra

# 1. Setup backend (S3 + DynamoDB)
bash scripts/setup-backend.sh

# 2. Initialize Terraform
terraform init -backend-config=backend-config.hcl

# 3. Validate
terraform validate

# 4. Plan
terraform plan

# 5. Deploy
terraform apply
```

## Using Make (Recommended)

```bash
# View all commands
make help

# Setup everything
make setup

# Deploy
make deploy

# Check drift
make check-drift

# Destroy (⚠️ Careful!)
make destroy
```

## Essential Commands

### Planning & Deployment

```bash
terraform plan                    # Show planned changes
terraform apply                   # Deploy
terraform apply -auto-approve     # Deploy without confirmation
terraform destroy                 # Destroy all (⚠️)
```

### State Management

```bash
terraform state list              # List all resources
terraform state show aws_vpc.main # Show specific resource
terraform refresh                 # Update state from AWS
terraform output                  # Show outputs
terraform output -json            # JSON format
```

### Code Quality

```bash
terraform fmt -recursive          # Format code
terraform validate               # Check syntax
TF_LOG=DEBUG terraform plan      # Debug output
```

### Drift Detection

```bash
bash scripts/check-drift.sh              # Check for drift
bash scripts/check-drift.sh --auto-approve # Auto-apply drift fixes
```

### Variables

```bash
terraform apply -var='instance_type=m5.large'  # Override variable
terraform apply -var-file=prod.tfvars          # Use variable file
export TF_VAR_instance_type=m5.large
terraform apply                                # Via env variable
```

## Common Scenarios

### Change Instance Count

```bash
terraform apply -var='asg_desired_capacity=5'
```

### Scale Down to Save Cost

```bash
terraform apply -var='instance_type=t3.micro' -var='asg_desired_capacity=1'
```

### Add SSH Access for Your IP

```bash
terraform apply -var='ssh_allowed_cidr=["203.0.113.0/32"]'
```

### Modify and Redeploy

```bash
# Edit main.tf
vim main.tf

# Plan and apply
terraform plan
terraform apply
```

### Emergency Cleanup

```bash
rm -rf .terraform
terraform init -backend-config=backend-config.hcl
```

## File Locations

| File               | Purpose                          |
| ------------------ | -------------------------------- |
| `main.tf`          | Resources definition             |
| `variables.tf`     | Input variables                  |
| `outputs.tf`       | Output values                    |
| `backend.tf`       | State backend config             |
| `user_data.sh`     | EC2 bootstrap script             |
| `terraform.tfvars` | Your configuration               |
| `.terraform/`      | Downloaded modules (git ignored) |
| `*.tfstate`        | State files (git ignored)        |

## Important Outputs

After `terraform apply`, view:

```bash
# Get load balancer DNS
terraform output alb_dns_name

# Get all outputs
terraform output

# Save to file
terraform output -json > outputs.json
```

## Troubleshooting

### Problem: Backend not found

```bash
terraform init -backend-config=backend-config.hcl -upgrade
```

### Problem: AWS credentials error

```bash
aws configure
# Or export AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY
```

### Problem: State locked

```bash
# Find lock ID
aws dynamodb scan --table-name terraform-locks

# Release lock
terraform force-unlock <LOCK_ID>
```

### Problem: Resource creation failed

```bash
# Check AWS console for errors
# Or enable debug:
TF_LOG=DEBUG terraform apply
```

## GitHub Actions Workflow

### Prerequisites

1. Set GitHub Secrets:

   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `ALERT_EMAIL`

2. Workflow runs automatically:
   - Every 6 hours (drift detection)
   - On push to `infra/` directory
   - Manual trigger available

### Approval Process

1. Drift detected → Email sent
2. GitHub issue created
3. Review changes in GitHub Actions
4. Approve to apply
5. Confirmation email sent

## Environment Variables

```bash
AWS_REGION=us-east-1
TF_VAR_instance_type=t3.medium
TF_VAR_asg_desired_capacity=2
TF_LOG=DEBUG  # Enable debug logging
```

## Directory Structure Reminder

```
infra/
├── main.tf              # Resources
├── variables.tf         # Variables
├── outputs.tf           # Outputs
├── user_data.sh         # EC2 startup
├── terraform.tfvars     # Your config (git ignored)
├── scripts/             # Helper scripts
├── playbooks/           # Ansible playbooks
├── inventory/           # Generated inventory
├── .github/workflows/   # CI/CD
└── [Documentation]      # Guides
```

## Cost Monitoring

```bash
# Estimate cost
make estimate-cost

# View resources
make show-instances    # EC2 instances
make show-asg          # Auto Scaling Group
make show-alb          # Load Balancer
make show-sg           # Security Groups
```

## Safety Tips

✅ Always run `terraform plan` before `apply`
✅ Review changes carefully
✅ Use `terraform destroy` with caution
✅ Keep state backed up
✅ Commit only code (not `*.tfstate`)
✅ Use separate `*.tfvars` per environment
✅ Enable drift detection for production

## Useful Links

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Best Practices](https://www.terraform.io/docs/cloud/guides/recommended-practices)
- [AWS EC2 Documentation](https://docs.aws.amazon.com/ec2/)

---

**Tip**: Bookmark this file! Use `make help` for command reference.
