# Quick Start Guide

Get your infrastructure up and running in 5 steps.

## Prerequisites

```bash
# Install required tools
brew install terraform aws-cli ansible  # macOS
# or
apt install terraform awscli ansible    # Linux

# Verify installation
terraform version
aws --version
ansible --version
```

## Step 1: Configure AWS

```bash
# Configure AWS credentials
aws configure

# Verify credentials
aws sts get-caller-identity
```

## Step 2: Set Up Backend

```bash
cd infra

# Create S3 bucket and DynamoDB table
bash scripts/setup-backend.sh
```

**Output**: Backend is ready

```
Bucket: devops-stage-6-terraform-state
DynamoDB Table: terraform-locks
```

## Step 3: Initialize Terraform

```bash
# Initialize Terraform with backend
terraform init -backend-config=backend-config.hcl

# Verify
terraform state list
# Output should be empty (no resources yet)
```

## Step 4: Plan Infrastructure

```bash
# Copy example variables
cp terraform.tfvars.example terraform.tfvars

# Optional: Customize terraform.tfvars
vim terraform.tfvars

# Review the plan
terraform plan
```

**You'll see**:

- 20+ resources to be created
- VPC, subnets, security groups
- Load balancer, ASG, EC2 launch template
- IAM roles and instance profile

## Step 5: Deploy Infrastructure

```bash
# Apply the configuration
terraform apply

# Review and confirm
# Type: yes

# Wait ~5-10 minutes for deployment
```

**After completion, you'll get**:

```
Outputs:

alb_dns_name = "app-xxx.us-east-1.elb.amazonaws.com"
asg_name = "devops-stage-6-asg"
vpc_id = "vpc-xxx"
...
```

## Verify Deployment

```bash
# Get outputs
terraform output

# Test application health
curl http://$(terraform output -raw alb_dns_name)/health

# Check running instances
aws ec2 describe-instances --filters "Name=tag:Environment,Values=dev" \
  --query 'Reservations[].Instances[].[InstanceId,State.Name,PrivateIpAddress]'
```

## View Ansible Inventory

```bash
# Generated automatically by Terraform
cat inventory/hosts.ini

# Test connection to instances
ansible all -i inventory/hosts.ini -m ping
```

## Set Up Drift Detection

### Local

```bash
# Check for drift
bash scripts/check-drift.sh

# Auto-approve changes
bash scripts/check-drift.sh --auto-approve
```

### GitHub Actions

1. Go to repository **Settings** → **Secrets**
2. Add secrets:

   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `ALERT_EMAIL=your-email@example.com`

3. Workflow runs automatically every 6 hours

## Common Commands

```bash
# View state
terraform state list
terraform state show aws_vpc.main

# Change capacity
terraform apply -var='asg_desired_capacity=5'

# Destroy (⚠️ Careful!)
terraform destroy

# View outputs
terraform output
terraform output alb_dns_name

# Format code
terraform fmt -recursive

# Validate syntax
terraform validate

# Get resource details
terraform show -json | jq '.resources[] | select(.type=="aws_instance")'
```

## Troubleshooting

### Backend not found

```bash
terraform init -backend-config=backend-config.hcl -upgrade
```

### AWS credentials error

```bash
aws configure
export AWS_PROFILE=default
```

### Terraform version mismatch

```bash
terraform version
# Update if needed
brew upgrade terraform
```

### Instances not ready

```bash
# Wait a few minutes, then check
aws ec2 describe-instances --query 'Reservations[].Instances[].[InstanceId,State.Name]'

# Check user data logs
aws ssm start-session --target i-xxx
cat /var/log/user-data.log
```

## Next Steps

1. **Configure DNS**: Point your domain to the ALB DNS name
2. **Enable HTTPS**: Add SSL certificate to ALB
3. **Set up monitoring**: Enable CloudWatch dashboards
4. **Deploy applications**: Use Ansible to deploy services
5. **Configure backups**: Set up automated backups

## Documentation

- Full guide: [README.md](./README.md)
- Variables: [VARIABLES.md](./VARIABLES.md)
- Drift detection: [DRIFT_DETECTION.md](./DRIFT_DETECTION.md)

## Clean Up (if needed)

```bash
# Remove all infrastructure
cd infra
terraform destroy

# Remove backend
bash scripts/setup-backend.sh --destroy  # Optional
```

## Support

For issues:

1. Check logs: `TF_LOG=DEBUG terraform plan`
2. Review AWS console for errors
3. Check Ansible logs: `ansible-playbook -vvv`

---

**Estimated time**: 15-20 minutes
**Cost**: ~$50-100/month for dev environment

Enjoy your infrastructure! 🚀
