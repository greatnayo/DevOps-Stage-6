# Single Command Deployment Checklist

## Pre-Deployment Checklist

### Environment Setup

- [ ] Terraform >= 1.0 installed and in PATH
- [ ] AWS CLI v2 installed and in PATH
- [ ] Ansible >= 2.9 installed and in PATH
- [ ] Python 3.7+ installed and in PATH
- [ ] curl, jq, dig installed
- [ ] Git installed and repository cloned

### AWS Configuration

- [ ] AWS credentials configured (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY)
- [ ] AWS region set (AWS_REGION or in terraform.tfvars)
- [ ] IAM user has appropriate permissions for EC2, ELB, VPC, S3, DynamoDB, IAM, AutoScaling

### SSH and Keys

- [ ] SSH key pair created in AWS
- [ ] SSH private key downloaded (~/.ssh/id_rsa)
- [ ] SSH key permissions set (chmod 600)

### Terraform Configuration

- [ ] Downloaded repository from GitHub
- [ ] Navigated to `infra/` directory
- [ ] Created `terraform.tfvars` with appropriate values
- [ ] Reviewed `variables.tf` for all available options
- [ ] Terraform initialized: `terraform init`
- [ ] Configuration validated: `terraform validate`

### Ansible Configuration

- [ ] Reviewed `playbooks/site.yml`
- [ ] Reviewed role configurations in `playbooks/roles/`
- [ ] Verified all required Ansible plugins installed

### Documentation

- [ ] Read `README.md` in infra directory
- [ ] Read `SINGLE_COMMAND_DEPLOYMENT.md`
- [ ] Understood deployment stages and flow

## Pre-Deployment Testing

### Tool Verification

- [ ] Terraform validation passes: `terraform validate`
- [ ] AWS CLI can access account: `aws sts get-caller-identity`
- [ ] Ansible is properly configured: `ansible --version`
- [ ] All required tools available: curl, jq, dig, python3
- [ ] Directory structure is correct

### Backend Setup (First Time Only)

- [ ] S3 bucket created
- [ ] DynamoDB table created
- [ ] Backend configuration working
- [ ] Run: `make setup-backend`

### Terraform Initialization

- [ ] Terraform initialized: `terraform init`
- [ ] Backend configured properly
- [ ] Provider plugins downloaded
- [ ] No initialization errors

### Configuration Validation

- [ ] Configuration syntax valid: `terraform validate`
- [ ] Plan shows expected resources: `terraform plan`
- [ ] Plan output reviewed and confirmed

## Deployment Execution

### Start Deployment

```bash
cd infra
terraform apply -auto-approve
```

- [ ] Command executed successfully
- [ ] Deployment started without errors
- [ ] Real-time logs are visible

### Monitor Each Stage

#### Stage 1: Infrastructure Provisioning (2-5 minutes)

- [ ] VPC and subnets created
- [ ] Internet Gateway created
- [ ] NAT Gateway created
- [ ] Security groups created
- [ ] Load Balancer created
- [ ] Auto Scaling Group created
- [ ] EC2 instances launching
- [ ] No resource creation errors

#### Stage 2: Inventory Generation (1 minute)

- [ ] Inventory file created
- [ ] All instances listed
- [ ] Private IP addresses populated
- [ ] Inventory format correct

#### Stage 3: Instance Readiness (2-5 minutes)

- [ ] Health check polling started
- [ ] Target count matches ASG capacity
- [ ] Instances transitioning to healthy state
- [ ] All instances reach healthy status
- [ ] No timeout errors

#### Stage 4: Ansible Deployment (3-10 minutes)

- [ ] Ansible connection established
- [ ] All playbook tasks executed
- [ ] No Ansible connection errors
- [ ] No failed tasks
- [ ] Applications deployed successfully

#### Stage 5: Traefik Configuration (2-5 minutes)

- [ ] Traefik configuration created
- [ ] Traefik playbook executed
- [ ] Traefik containers started
- [ ] SSL configuration applied (if enabled)
- [ ] No Traefik deployment errors

#### Stage 6: Health Validation (1-3 minutes)

- [ ] ALB DNS name resolves
- [ ] HTTP endpoint responds
- [ ] Health check endpoint returns 200
- [ ] Application endpoints accessible
- [ ] No validation timeouts

#### Stage 7: Deployment Summary

- [ ] Summary displayed
- [ ] All stages marked COMPLETE
- [ ] Application endpoint accessible
- [ ] Dashboard URL available (if SSL enabled)

**Total Expected Duration:** 10-30 minutes

## Post-Deployment Verification

### Access Application

- [ ] ALB DNS name obtained
- [ ] HTTP request successful
- [ ] Response received from application
- [ ] Status code is 200 or expected code

### Verify Instances

- [ ] All desired instances running
- [ ] Instances have private IP addresses
- [ ] Instance types match configuration
- [ ] No failed or stopping instances

### Check Ansible Inventory

- [ ] Inventory file exists and is readable
- [ ] All instances listed
- [ ] Ansible variables configured
- [ ] No syntax errors

### Test Ansible Connectivity

- [ ] Ansible can connect to all instances
- [ ] SSH keys working properly
- [ ] All instances respond to ping
- [ ] No connection refused errors

### View Terraform Outputs

- [ ] Terraform outputs displayed
- [ ] ALB DNS name is correct
- [ ] VPC ID is present
- [ ] ASG name is correct
- [ ] All expected outputs present

### Check Traefik (if enabled)

- [ ] Traefik responds to health check
- [ ] Traefik dashboard accessible
- [ ] HTTP/HTTPS routing configured
- [ ] SSL certificates installed

## Troubleshooting

### Terraform Errors

- [ ] Check terraform logs: `TF_LOG=DEBUG terraform apply`
- [ ] Verify AWS credentials: `aws sts get-caller-identity`
- [ ] Check terraform state: `terraform state list`

### AWS Errors

- [ ] Verify IAM permissions
- [ ] Check resource quotas
- [ ] Check region configuration
- [ ] Review AWS Console for resource details

### Ansible Errors

- [ ] Test connectivity: `make ping-hosts`
- [ ] Check inventory: `cat inventory/hosts.ini`
- [ ] Run playbook manually with verbose: `-vvv`

### Instance Issues

- [ ] Check instance console output
- [ ] Review security group rules
- [ ] Check user-data script logs

## Idempotency Verification

After initial deployment succeeds:

```bash
terraform apply -auto-approve
```

- [ ] Second apply shows no changes
- [ ] All resources remain unchanged
- [ ] Idempotency confirmed

Then try again:

```bash
terraform apply -auto-approve
```

- [ ] Third apply also shows no changes
- [ ] Consistent idempotent behavior

## Scaling Verification

Edit `terraform.tfvars` to increase ASG capacity, then run:

```bash
terraform apply -auto-approve
```

- [ ] New instance launched
- [ ] Inventory automatically updated
- [ ] New instance becomes healthy
- [ ] Ansible deployment runs on new instance
- [ ] Application accessible through load balancer

## Sign-off

- [ ] All pre-deployment checklist items completed
- [ ] Deployment executed successfully
- [ ] All 7 stages completed without critical errors
- [ ] Post-deployment verification passed
- [ ] Application is accessible and functional
- [ ] Infrastructure is idempotent
- [ ] Team notified of successful deployment

**Deployment Date:** ********\_\_\_********

**Deployed By:** ********\_\_\_********

**Notes/Issues:**

```
_____________________________________________________________
_____________________________________________________________
_____________________________________________________________
```

- [ ] Environment set (dev/staging/prod)
- [ ] Instance type selected
- [ ] SSH CIDR blocks restricted appropriately

### Code Quality

- [ ] Run: `terraform fmt -recursive` ✅
- [ ] Run: `terraform validate` ✅
- [ ] Verify: `terraform plan` produces expected output

## AWS Configuration

### VPC & Networking

- [ ] VPC CIDR blocks configured (10.0.0.0/16)
- [ ] Public subnet CIDR (10.0.1.0/24)
- [ ] Private subnet CIDR (10.0.2.0/24)
- [ ] Security groups configured for ALB and app servers

### EC2 Configuration

- [ ] AMI ID valid for the region
- [ ] Instance type appropriate for workload
- [ ] IAM role permissions correct
- [ ] User data script configured

### Auto Scaling

- [ ] Min size: 1+
- [ ] Max size: >= Min size
- [ ] Desired capacity: between Min and Max
- [ ] Health check configured

### Load Balancer

- [ ] ALB health check path: `/health`
- [ ] ALB health check interval: 30 seconds
- [ ] ALB ports: 80 (HTTP)
- [ ] Target group port: 8080

## Ansible Configuration

### Playbooks

- [ ] `playbooks/site.yml` reviewed
- [ ] `playbooks/roles/common/tasks/main.yml` reviewed
- [ ] Inventory template `templates/inventory.tpl` configured

### Ansible Execution

- [ ] `scripts/run_ansible.sh` executable: `chmod +x scripts/run_ansible.sh`
- [ ] Ansible dependencies installed: `pip install ansible boto3`

## CI/CD Configuration (GitHub Actions)

### GitHub Secrets

- [ ] `AWS_ACCESS_KEY_ID` set
- [ ] `AWS_SECRET_ACCESS_KEY` set
- [ ] `ALERT_EMAIL` set (for drift notifications)
- [ ] Secrets are NOT exposed in logs

### Workflow Configuration

- [ ] `.github/workflows/terraform-drift-detection.yml` exists
- [ ] Workflow file syntax valid
- [ ] Cron schedule configured (default: every 6 hours)
- [ ] Email notification addresses correct

### Environment Protection

- [ ] GitHub Environment `terraform-apply-approval` configured (if needed)
- [ ] Required reviewers assigned (if needed)
- [ ] Branch protection rules configured (if needed)

## Email Notifications

### AWS SES (if using)

- [ ] Sender email verified in AWS SES
- [ ] Not in sandbox mode (if needed)
- [ ] Receiving email address valid
- [ ] `send_via_ses.sh` script configured

### GitHub Action Email

- [ ] `scripts/send-email/action.yml` configured
- [ ] `scripts/send-email/entrypoint.sh` executable

## Documentation Review

- [ ] README.md reviewed for architecture
- [ ] QUICKSTART.md read for deployment steps
- [ ] VARIABLES.md reviewed for all configuration options
- [ ] DRIFT_DETECTION.md understood for monitoring
- [ ] QUICK_REFERENCE.md bookmarked for commands

## Security Review

### Credentials & Secrets

- [ ] No AWS credentials in code
- [ ] No SSH keys in repository
- [ ] Secrets only in GitHub Secrets
- [ ] `.gitignore` prevents accidental commits

### Network Security

- [ ] SSH CIDR blocks restricted (not 0.0.0.0/0 in production)
- [ ] ALB security group only allows necessary ports
- [ ] App security group only allows ALB traffic
- [ ] NAT Gateway configured for private egress

### Access Control

- [ ] IAM roles have minimal permissions
- [ ] S3 bucket block public access enabled
- [ ] DynamoDB access restricted to Terraform user

### State Management

- [ ] S3 bucket encryption enabled
- [ ] S3 bucket versioning enabled
- [ ] State file access restricted
- [ ] DynamoDB table for locking exists

## Pre-Deployment Testing

```bash
cd infra

# Format check
[ ] terraform fmt -check -recursive

# Validation
[ ] terraform validate

# Planning
[ ] terraform plan

# Review output
[ ] Review ALL planned changes carefully
[ ] Verify correct number of resources
[ ] No unexpected deletions
```

## Deployment Execution

### Step 1: Create Initial Plan

```bash
terraform plan -out=tfplan
```

- [ ] Output reviewed
- [ ] Resources count reasonable
- [ ] No critical deletions

### Step 2: Apply Configuration

```bash
terraform apply tfplan
```

- [ ] Wait for completion (5-15 minutes)
- [ ] No errors during creation
- [ ] All resources successfully created

### Step 3: Verify Outputs

```bash
terraform output
```

- [ ] All outputs present
- [ ] ALB DNS name valid
- [ ] Instance IDs present

## Post-Deployment Verification

### Infrastructure Validation

```bash
# Get ALB DNS
LOAD_BALANCER=$(terraform output -raw alb_dns_name)

# Test health endpoint
[ ] curl http://$LOAD_BALANCER/health   # Should return 200

# Check instances
[ ] aws ec2 describe-instances | grep running

# Check ASG
[ ] aws autoscaling describe-auto-scaling-groups \
      --query 'AutoScalingGroups[*].DesiredCapacity'
```

### Ansible Validation

```bash
# Check inventory generated
[ ] ls -l inventory/hosts.ini

# Test connectivity
[ ] ansible all -i inventory/hosts.ini -m ping
```

### Application Validation

```bash
# Test application endpoints
[ ] curl http://$LOAD_BALANCER/health
[ ] curl http://$LOAD_BALANCER/api/v1/...
```

## Drift Detection Setup

### Local Drift Check

```bash
cd infra
bash scripts/check-drift.sh
```

- [ ] No drift detected on fresh deployment
- [ ] Output shows "No changes"

### GitHub Actions Setup

- [ ] Secrets configured
- [ ] Workflow enabled
- [ ] Manual trigger tested

### Email Notification Test

- [ ] Trigger workflow manually
- [ ] Verify email received
- [ ] Check drift alert content

## Documentation Updates

- [ ] Team notified of deployment
- [ ] Runbooks updated
- [ ] Architecture diagram confirmed
- [ ] Deployment notes documented
- [ ] Known issues listed
- [ ] Support contacts updated

## Monitoring Setup

### CloudWatch

- [ ] CloudWatch agent installed on instances
- [ ] Metrics publishing to CloudWatch
- [ ] Dashboards created (optional)
- [ ] Alarms configured (optional)

### Logging

- [ ] Application logs aggregated
- [ ] Terraform logs archived
- [ ] User data logs accessible

### Alerts

- [ ] Drift detection alerts working
- [ ] Email notifications tested
- [ ] On-call rotation updated

## Backup & Disaster Recovery

- [ ] Terraform state backed up
- [ ] S3 bucket versioning enabled
- [ ] Recovery procedure documented
- [ ] Backup tested (optional)

## Post-Deployment Monitoring

### Week 1

- [ ] Monitor instances for stability
- [ ] Check for unexpected costs
- [ ] Verify drift detection runs
- [ ] Review error logs
- [ ] Test failover (if applicable)

### Ongoing

- [ ] Monthly cost review
- [ ] Quarterly provider updates
- [ ] Annual security audit
- [ ] Backup restoration test

## Rollback Plan

If deployment fails:

```bash
# Option 1: Destroy and retry
terraform destroy
# Fix configuration
terraform apply

# Option 2: Targeted destruction
terraform destroy -target aws_autoscaling_group.app

# Option 3: Manual rollback
# Restore state from backup
aws s3 cp s3://bucket/backup/terraform.tfstate ./
```

- [ ] Rollback procedure understood
- [ ] Backup state files accessible
- [ ] Tested (optional but recommended)

## Sign-Off

- [ ] Project Manager approval
- [ ] Infrastructure team approval
- [ ] Security team approval (production)
- [ ] DevOps team approval
- [ ] Deployment date set
- [ ] Deployment window scheduled

---

## Summary

### Essential (Must Do)

1. ✅ AWS credentials configured
2. ✅ Backend setup: `bash scripts/setup-backend.sh`
3. ✅ Terraform init: `terraform init -backend-config=backend-config.hcl`
4. ✅ Variables configured: `terraform.tfvars`
5. ✅ Plan reviewed: `terraform plan`
6. ✅ Deploy: `terraform apply`
7. ✅ Outputs verified: `terraform output`
8. ✅ Health check: `curl http://ALB-DNS/health`

### Important (Should Do)

- ✅ GitHub secrets configured (for CI/CD)
- ✅ Drift detection tested
- ✅ Email notifications working
- ✅ Documentation reviewed

### Nice to Have (Could Do)

- ✅ Monitoring setup
- ✅ Backups configured
- ✅ Team trained
- ✅ Disaster recovery tested

---

**Status**: Ready for deployment ✅
**Last Updated**: 2025-11-28
**Next Review**: After first 24 hours of deployment
