# Single Command Deployment - Quick Reference

## The Single Command

```bash
cd infra
terraform apply -auto-approve
```

That's it! This deploys everything:

- ✓ Infrastructure (VPC, Subnets, ALB, ASG, EC2)
- ✓ Ansible inventory generation
- ✓ Application deployment
- ✓ Traefik reverse proxy with SSL
- ✓ Health checks and validation

## What Happens Step-by-Step

```
1. Terraform provisions AWS infrastructure
   └─> VPC, Subnets, Gateways, ALB, ASG, EC2
       ⏱ ~2-5 minutes

2. Terraform generates Ansible inventory from EC2 instances
   └─> Creates inventory/hosts.ini from running instances
       ⏱ ~1 minute

3. Wait for instances to pass health checks
   └─> Polls target group until all instances healthy
       ⏱ ~2-5 minutes

4. Run Ansible deployment playbooks
   └─> Installs dependencies
   └─> Deploys applications
   └─> Configures services
       ⏱ ~3-10 minutes

5. Deploy and configure Traefik
   └─> Creates Traefik config
   └─> Starts Traefik containers
   └─> Configures SSL (if enabled)
       ⏱ ~2-5 minutes

6. Validate deployment health
   └─> Tests ALB accessibility
   └─> Verifies application endpoints
       ⏱ ~1-3 minutes

7. Display deployment summary
   └─> Shows endpoints and next steps
       ⏱ Instant

Total: 10-30 minutes ✓
```

## Before You Deploy

### 1. Install Required Tools

```bash
# macOS
brew install terraform awscli ansible jq

# Ubuntu/Debian
sudo apt-get install terraform awscli ansible jq curl

# Check installation
terraform version
aws --version
ansible --version
```

### 2. Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_REGION="us-east-1"

# Or use AWS CLI configuration
aws configure
```

### 3. Create Configuration File

```bash
cd infra

# Create terraform.tfvars
cat > terraform.tfvars << 'EOF'
aws_region              = "us-east-1"
project_name            = "devops-stage-6"
environment             = "dev"
instance_type           = "t3.medium"
asg_desired_capacity    = 2
enable_ssl              = true
traefik_acme_email      = "your-email@example.com"
EOF
```

### 4. Initialize Terraform (First Time Only)

```bash
cd infra
make setup-backend    # Setup S3 & DynamoDB
terraform init        # Initialize Terraform
terraform validate    # Validate configuration
```

## Deploy

```bash
cd infra
terraform apply -auto-approve
```

## After Deployment

### Get Access Information

```bash
cd infra

# Get load balancer DNS
terraform output alb_dns_name

# Get all outputs
terraform output -json
```

### Test Application

```bash
# From the terraform output
ALB_DNS="app-xxxxx.elb.amazonaws.com"
curl http://$ALB_DNS/
```

### Check Infrastructure

```bash
cd infra

# List EC2 instances
make show-instances

# View Auto Scaling Group
make show-asg

# Check Ansible inventory
cat inventory/hosts.ini

# Test Ansible connectivity
make ping-hosts
```

### View Logs

```bash
# SSH to instance and check logs
ssh -i ~/.ssh/id_rsa ec2-user@<private-ip>
tail -f /var/log/user-data.log
docker logs container-name
```

## Common Operations

### Redeploy (Idempotent)

```bash
cd infra
terraform apply -auto-approve
```

**Result:** No changes if nothing changed. Services already running.

### Scale Up

```bash
cd infra

# Edit terraform.tfvars
# Change: asg_desired_capacity = 3

terraform apply -auto-approve
```

**Result:** New instance added, automatically deployed.

### Manually Run Ansible

```bash
cd infra
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -v
```

### Destroy Everything

```bash
cd infra
terraform destroy -auto-approve
```

⚠️ **WARNING:** This deletes all infrastructure and data!

### Check Infrastructure Drift

```bash
cd infra
terraform plan
```

If resources changed outside Terraform, it will show.

### View Specific Outputs

```bash
cd infra

# Get VPC ID
terraform output vpc_id

# Get ALB DNS
terraform output alb_dns_name

# Get all as JSON
terraform output -json
```

## Troubleshooting

### Deployment Hangs Waiting for Instances

```bash
# Check target group health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...

# Check instance console
aws ec2 get-console-output --instance-ids i-xxxxx

# SSH and check logs
ssh -i ~/.ssh/id_rsa ec2-user@<instance-ip>
tail -f /var/log/user-data.log
```

### Ansible Fails

```bash
# Test connectivity
cd infra
ansible all -i inventory/hosts.ini -m ping

# Run manually with verbose
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -vvv

# Check SSH key
ls -la ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
```

### Can't Access Application

```bash
# Check security groups
aws ec2 describe-security-groups

# Check ALB listener rules
aws elbv2 describe-listeners --load-balancer-arn <arn>

# Test port connectivity
telnet <alb-dns> 80
curl -v http://<alb-dns>/
```

### Terraform State Issues

```bash
# View current state
terraform state list
terraform state show <resource>

# Refresh state
terraform refresh

# Emergency: Clear locks
make -C infra clean-locks
```

## Configuration Options

### Key Variables

```hcl
# Infrastructure
aws_region              = "us-east-1"
environment             = "dev"  # dev, staging, prod
instance_type           = "t3.medium"
asg_desired_capacity    = 2

# Deployment
instance_ready_timeout          = 300  # seconds
enable_ssl                      = true
ssl_provider                    = "letsencrypt"
traefik_acme_email              = "admin@example.com"
deployment_health_check_retries = 30
```

## Monitoring

### CloudWatch Logs

```bash
aws logs tail /aws/ec2/application --follow
```

### Check Deployment Logs

```bash
# Ansible logs
tail -f infra/logs/ansible-deployment.log

# Traefik logs
docker logs traefik

# Application logs
docker logs <app-container>
```

### Monitor Resources

```bash
# CPU/Memory usage
top

# Disk usage
df -h

# Network connections
netstat -ant
```

## Important Notes

### Costs

- **ALB:** ~$20/month
- **EC2 t3.medium:** ~$30-60/month per instance
- **Data transfer:** ~$5-15/month
- **Total (2 instances):** ~$100-150/month

### Security

- Change default SSH CIDR to restrict access
- Use AWS Systems Manager Session Manager instead of SSH
- Enable VPC Flow Logs
- Review security group rules regularly

### Backups

- Terraform state is stored in S3 with encryption
- Instance data is NOT automatically backed up
- Take snapshots of important instances

### Idempotency

```bash
# Deployments are idempotent (can run multiple times safely)
terraform apply -auto-approve  # First run
terraform apply -auto-approve  # No changes
terraform apply -auto-approve  # Still no changes
```

## Getting Help

### View All Make Targets

```bash
cd infra
make help
```

### Terraform Documentation

- [AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Docs](https://www.terraform.io/docs)

### Ansible Documentation

- [Ansible Docs](https://docs.ansible.com/)
- [Ansible Galaxy](https://galaxy.ansible.com/)

### Useful Commands

```bash
cd infra

# Show what will be created
terraform plan

# Show detailed plan
terraform plan -out=tfplan && terraform show tfplan

# Debug mode
TF_LOG=DEBUG terraform apply -auto-approve

# Validate configuration
terraform fmt -recursive
terraform validate

# Check for drift
terraform plan -refresh-only
```

## Deployment Checklist

- [ ] AWS credentials configured
- [ ] Terraform installed (>= 1.0)
- [ ] Ansible installed (>= 2.9)
- [ ] terraform.tfvars created with your values
- [ ] `terraform validate` passes
- [ ] Backend initialized with `make setup-backend`
- [ ] No errors in `terraform init`
- [ ] Ready to deploy!

```bash
cd infra
terraform apply -auto-approve
```

That's it! Everything deploys automatically. ✓
