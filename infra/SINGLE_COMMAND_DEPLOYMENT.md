# Single Command Deployment Guide

## Overview

This guide explains how to deploy the entire infrastructure, configure Ansible, and deploy applications using a single Terraform command.

## Quick Start

```bash
cd infra
terraform apply -auto-approve
```

This single command will:

1. ✓ Provision AWS infrastructure (VPC, Subnets, ALB, ASG, EC2)
2. ✓ Generate Ansible inventory dynamically from EC2 instances
3. ✓ Deploy applications via Ansible playbooks
4. ✓ Configure Traefik reverse proxy with SSL/TLS
5. ✓ Validate deployment health and accessibility
6. ✓ Generate deployment summary

## Prerequisites

Before running the deployment, ensure you have:

### Required Tools

- Terraform >= 1.0
- AWS CLI v2
- Ansible >= 2.9
- Python 3.7+
- curl
- jq
- dig (for DNS resolution)

### AWS Configuration

- AWS credentials configured (via `~/.aws/credentials` or environment variables)
- Appropriate IAM permissions to create EC2, VPC, ALB, RDS resources
- Key pair created in your AWS region

### Configuration Files

```
infra/
├── terraform.tfvars          # Your custom configuration
├── variables.tf              # Variable definitions
├── main.tf                   # Infrastructure resources
├── deployment.tf             # Deployment orchestration
└── playbooks/
    └── site.yml             # Ansible playbooks
```

## Configuration

### 1. Set AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_REGION="us-east-1"
```

### 2. Configure Terraform Variables

Edit or create `terraform.tfvars`:

```hcl
# Infrastructure Configuration
aws_region              = "us-east-1"
project_name            = "devops-stage-6"
environment             = "dev"
vpc_cidr                = "10.0.0.0/16"
instance_type           = "t3.medium"
asg_desired_capacity    = 2

# Deployment Configuration
enable_ssl              = true
ssl_provider            = "letsencrypt"
traefik_acme_email      = "your-email@example.com"
traefik_dashboard_domain = "traefik.yourdomain.com"

# Timeouts and Retry Configuration
instance_ready_timeout  = 300
deployment_health_check_retries = 30
```

### 3. Initialize Terraform Backend (First Time Only)

```bash
cd infra

# Setup S3 backend for state management
make setup-backend

# Initialize Terraform
terraform init
```

## Deployment Process

### Stage 1: Infrastructure Provisioning

Terraform creates:

- VPC with public and private subnets
- Internet Gateway and NAT Gateway
- Application Load Balancer (ALB)
- Auto Scaling Group (ASG) with EC2 instances
- Security Groups with proper ingress/egress rules
- IAM roles and policies

```
terraform apply -auto-approve
[INFO] Provisioning infrastructure...
[INFO] ✓ VPC created
[INFO] ✓ Load Balancer created
[INFO] ✓ Auto Scaling Group created
[INFO] ✓ EC2 instances launching
```

### Stage 2: Inventory Generation

Once EC2 instances are provisioned:

- Terraform generates dynamic Ansible inventory from running instances
- Inventory is pulled from the ALB target group
- Private IP addresses are used for internal communication

```
Generated inventory at: infra/inventory/hosts.ini
[all_instances]
devops-stage-6-app-instance-1 ansible_host=10.0.2.10
devops-stage-6-app-instance-2 ansible_host=10.0.2.11
```

### Stage 3: Instance Readiness Check

The deployment waits for all instances to:

- Pass ALB health checks
- Become accessible via SSH
- Have Docker and dependencies available

```
[INFO] Waiting for instances...
[INFO] Healthy targets: 0/2
[INFO] Waiting for instances... (60/300s)
[INFO] Healthy targets: 2/2
[INFO] ✓ All instances are healthy
```

### Stage 4: Ansible Deployment

Application deployment runs Ansible playbooks:

```bash
ansible-playbook -i inventory/hosts.ini playbooks/site.yml \
  -e "environment=dev" \
  -e "project=devops-stage-6" \
  -v
```

Playbooks execute:

- **dependencies**: Install system packages, Docker, runtime dependencies
- **deploy**: Deploy application containers, configure environment
- **monitoring**: Setup monitoring and logging

### Stage 5: Traefik Configuration

Traefik reverse proxy is deployed with:

- SSL/TLS certificates (Let's Encrypt or ACM)
- HTTP to HTTPS redirect
- Rate limiting and CORS middleware
- Dashboard for management

```
[INFO] Deploying Traefik...
[INFO] ✓ Traefik container started
[INFO] ✓ SSL certificates configured
[INFO] Dashboard: https://traefik.yourdomain.com
```

### Stage 6: Health Validation

Final validation checks:

- ALB responds to health checks
- Application endpoints are accessible
- All instances report healthy status
- Traefik is accepting traffic

```
[INFO] Validating deployment...
[INFO] ✓ ALB is responding to health checks
[INFO] ✓ Application endpoint: http://alb-dns-name.elb.amazonaws.com
[INFO] ✓ HTTP Response Code: 200
```

## Idempotent Deployment

The deployment is designed to be **idempotent**:

```bash
# Run multiple times with the same result
terraform apply -auto-approve
terraform apply -auto-approve  # No changes on second run
terraform apply -auto-approve  # No changes on third run
```

This works by:

1. Terraform detecting unchanged infrastructure
2. Ansible playbooks checking if services are already running
3. Docker containers checking if they're already deployed
4. Skipping unnecessary updates and restarts

## Deployment Outputs

After successful deployment, you'll see:

```
DEPLOYMENT SUMMARY
════════════════════════════════════════════════

Deployment ID: devops-stage-6-2025-11-28-1430
Environment: dev
Project: devops-stage-6

Infrastructure
✓ VPC and Subnets: Provisioned
✓ Load Balancer: Active
✓ Auto Scaling Group: Active
✓ Security Groups: Configured

Application Endpoints
Primary Load Balancer:
  http://app-4c82d2.us-east-1.elb.amazonaws.com

SSL/TLS Status: Enabled
Provider: Let's Encrypt
Traefik Dashboard:
  https://traefik.yourdomain.com

Next Steps
1. Monitor your application
2. Check logs on instances
3. Run Ansible manually
4. View Terraform outputs
5. Check infrastructure drift
```

## Viewing Terraform Outputs

```bash
cd infra

# All outputs
terraform output

# Specific output
terraform output alb_dns_name

# JSON format
terraform output -json
```

## Managing the Deployment

### View Current Infrastructure

```bash
make -C infra show-instances
make -C infra show-asg
make -C infra show-alb
```

### Check Ansible Connectivity

```bash
make -C infra ping-hosts
```

### Regenerate Inventory

```bash
make -C infra gen-inventory
```

### Manual Ansible Re-deployment

```bash
make -C infra run-ansible
```

## Scaling the Deployment

### Increase Instance Count

```hcl
# In terraform.tfvars
asg_desired_capacity = 4  # Changed from 2
```

Then apply:

```bash
terraform apply -auto-approve
```

The deployment will:

- Add new instances to ASG
- Wait for health checks to pass
- Update Ansible inventory
- Deploy to new instances

### Change Instance Type

```hcl
# In terraform.tfvars
instance_type = "t3.large"  # Changed from t3.medium
```

Then apply:

```bash
terraform apply -auto-approve
```

## Troubleshooting

### Instances Not Becoming Healthy

```bash
# Check instance logs
aws ec2 get-console-output --instance-ids i-xxxxx

# View user data script output
ssh -i ~/.ssh/key.pem ec2-user@instance-ip
tail -f /var/log/user-data.log

# Check security group rules
make -C infra show-sg
```

### Ansible Playbook Failures

```bash
# Run manually with verbose output
cd infra
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -vvv

# Check inventory generation
cat inventory/hosts.ini

# Test connectivity
ansible all -i inventory/hosts.ini -m ping
```

### Application Not Accessible

```bash
# Check ALB health
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:...

# Check security groups
aws ec2 describe-security-groups --group-ids sg-xxxxx

# Check application logs on instance
ssh -i ~/.ssh/key.pem ec2-user@instance-ip
docker logs container-name
```

### Traefik Not Responding

```bash
# SSH to instance and check Traefik
docker ps | grep traefik
docker logs traefik

# Check Traefik configuration
docker exec traefik cat /traefik.yml

# Access dashboard
curl http://instance-ip:8080/dashboard/
```

## Advanced Configuration

### Custom Ansible Variables

Create `terraform.tfvars.json`:

```json
{
  "environment": "prod",
  "instance_type": "t3.large",
  "asg_desired_capacity": 5,
  "enable_ssl": true,
  "ssl_provider": "acm"
}
```

### Environment-Specific Deployment

```bash
# Dev environment
terraform apply -auto-approve -var-file="environments/dev.tfvars"

# Prod environment
terraform apply -auto-approve -var-file="environments/prod.tfvars"
```

### Partial Deployment (Testing)

```bash
# Only create infrastructure, skip Ansible
terraform apply -auto-approve -target=aws_autoscaling_group.app

# Later, manually run Ansible
make -C infra run-ansible
```

## Monitoring and Logs

### CloudWatch Logs

```bash
# View EC2 instance logs
aws logs tail /aws/ec2/application --follow
```

### Ansible Logs

```bash
# View Ansible execution logs
tail -f infra/logs/ansible-deployment.log
```

### Application Logs

```bash
# SSH to instance
ssh -i ~/.ssh/key.pem ec2-user@instance-ip

# View Docker logs
docker logs -f app-container

# View Traefik logs
docker logs -f traefik
```

## Cleanup and Destruction

### Destroy Infrastructure

```bash
cd infra

# Plan destruction
terraform plan -destroy

# Destroy all resources
terraform destroy

# Auto-approve destruction
terraform destroy -auto-approve
```

### Remove State Files

```bash
# WARNING: This removes Terraform state
make -C infra clean
```

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Deploy Infrastructure

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: hashicorp/setup-terraform@v1

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v1
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}

      - name: Deploy infrastructure
        run: |
          cd infra
          terraform init
          terraform apply -auto-approve
```

## Best Practices

1. **Use Variables**: Always use `terraform.tfvars` for environment-specific config
2. **Plan First**: Run `terraform plan` before `terraform apply`
3. **Version Control**: Don't commit secrets to Git
4. **State Management**: Keep Terraform state in S3 with encryption
5. **Tagging**: Add appropriate tags for cost allocation and tracking
6. **Monitoring**: Set up CloudWatch alarms for production deployments
7. **Testing**: Test changes in dev environment first
8. **Backups**: Backup Terraform state regularly
9. **Documentation**: Document custom variables and configurations
10. **Security**: Restrict SSH access, use security groups properly

## Performance Optimization

### Faster Deployments

```hcl
# Increase parallelism
terraform apply -auto-approve -parallelism=10
```

### Instance Launch Optimization

```hcl
# Use faster AMI or add Pre-built Docker images
# Reduce instance_ready_timeout if possible
instance_ready_timeout = 180
```

### Ansible Optimization

```bash
# Enable Ansible pipelining
export ANSIBLE_PIPELINING=True

# Increase forks
ansible-playbook -i inventory/hosts.ini playbooks/site.yml -f 10
```

## Support and Documentation

For more information:

- [Terraform AWS Provider Docs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [Traefik Documentation](https://doc.traefik.io/)
- [AWS Infrastructure Documentation](../infra/README.md)
