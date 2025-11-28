# Single Command Deployment Verification Guide

## How to Verify the Implementation

This guide provides step-by-step instructions to verify that the single-command deployment system is working correctly.

## Pre-Deployment Verification

### 1. Verify All Files Are in Place

```bash
cd /home/nayo/stage-6/DevOps-Stage-6/infra

# Check main Terraform files
ls -lh main.tf variables.tf deployment.tf outputs.tf

# Check scripts are executable
ls -lh scripts/wait_for_instances.sh scripts/run_ansible_full.sh \
        scripts/deploy_traefik.sh scripts/validate_deployment.sh \
        scripts/deployment_summary.sh

# Check templates
ls -lh templates/traefik-config.tpl templates/inventory.tpl

# Check documentation
ls -lh SINGLE_COMMAND_DEPLOYMENT.md SINGLE_COMMAND_QUICK_REFERENCE.md \
       DEPLOYMENT_CHECKLIST.md
```

**Expected Output:**

```
-rw-r--r-- main.tf
-rw-r--r-- variables.tf (expanded with new variables)
-rw-r--r-- deployment.tf (new file)
-rw-r--r-- outputs.tf
-rwxr-xr-x scripts/wait_for_instances.sh
-rwxr-xr-x scripts/run_ansible_full.sh
-rwxr-xr-x scripts/deploy_traefik.sh
-rwxr-xr-x scripts/validate_deployment.sh
-rwxr-xr-x scripts/deployment_summary.sh
-rw-r--r-- templates/traefik-config.tpl
-rw-r--r-- templates/inventory.tpl
-rw-r--r-- SINGLE_COMMAND_DEPLOYMENT.md
-rw-r--r-- SINGLE_COMMAND_QUICK_REFERENCE.md
-rw-r--r-- DEPLOYMENT_CHECKLIST.md
```

✅ **Pass:** All files present and scripts are executable

### 2. Verify Terraform Configuration

```bash
cd infra

# Initialize Terraform
terraform init

# Validate configuration
terraform validate
```

**Expected Output:**

```
Success! The configuration is valid.
```

✅ **Pass:** Terraform validates without errors

### 3. Verify Variables

```bash
cd infra

# Create test terraform.tfvars
cat > terraform.tfvars << 'EOF'
aws_region              = "us-east-1"
project_name            = "devops-stage-6-test"
environment             = "dev"
instance_type           = "t3.medium"
asg_desired_capacity    = 1
enable_ssl              = true
ssl_provider            = "letsencrypt"
traefik_acme_email      = "test@example.com"
traefik_dashboard_domain = "traefik.example.com"
EOF

# Validate again
terraform validate
```

✅ **Pass:** Configuration validates with custom variables

### 4. Verify Scripts

```bash
cd infra/scripts

# Check script syntax
bash -n wait_for_instances.sh
bash -n run_ansible_full.sh
bash -n deploy_traefik.sh
bash -n validate_deployment.sh
bash -n deployment_summary.sh
```

**Expected Output:**

```
(No errors or warnings)
```

✅ **Pass:** All scripts have valid bash syntax

### 5. Verify Dependencies

```bash
# Check required tools
command -v terraform && echo "✓ Terraform" || echo "✗ Terraform"
command -v aws && echo "✓ AWS CLI" || echo "✗ AWS CLI"
command -v ansible-playbook && echo "✓ Ansible" || echo "✗ Ansible"
command -v python3 && echo "✓ Python3" || echo "✗ Python3"
command -v curl && echo "✓ curl" || echo "✗ curl"
command -v jq && echo "✓ jq" || echo "✗ jq"
command -v dig && echo "✓ dig" || echo "✗ dig"

# Check versions
terraform version | head -1
aws --version
ansible --version | head -1
python3 --version
curl --version | head -1
jq --version
```

✅ **Pass:** All required tools installed and in PATH

## Deployment Verification

### 1. Check AWS Credentials

```bash
# Verify credentials are set
aws sts get-caller-identity
```

**Expected Output:**

```json
{
  "UserId": "AIDAI...",
  "Account": "123456789012",
  "Arn": "arn:aws:iam::123456789012:user/your-user"
}
```

✅ **Pass:** AWS credentials are valid

### 2. Prepare for Deployment

```bash
cd infra

# Create infrastructure directory if needed
mkdir -p inventory
mkdir -p traefik
mkdir -p logs

# Verify Makefile targets exist
make help | grep -E "(init|plan|apply|destroy|gen-inventory|run-ansible)"
```

✅ **Pass:** Infrastructure directories created

### 3. Test Terraform Plan

```bash
cd infra

# Create plan without applying
terraform plan -out=tfplan

# Show plan details
terraform show tfplan | head -50
```

**Expected Output:**

```
Plan: XX to add, 0 to change, 0 to destroy.
```

✅ **Pass:** Terraform plan shows resources to be created

### 4. Verify Deployment.tf Contents

```bash
cd infra

# Check deployment.tf has all stages
grep -c "Stage" deployment.tf

# Verify null_resource definitions
grep "resource \"null_resource\"" deployment.tf | wc -l

# Check provisioners
grep "provisioner \"local-exec\"" deployment.tf | wc -l
```

**Expected Output:**

```
7  (7 stages)
7  (7 null_resource blocks)
7  (7 provisioners)
```

✅ **Pass:** deployment.tf contains all 7 stages

### 5. Verify Variables.tf Additions

```bash
cd infra

# Check new deployment variables
grep -E "instance_ready_timeout|enable_ssl|ssl_provider" variables.tf

# Count total variables
grep "^variable" variables.tf | wc -l
```

**Expected Output:**

```
(Shows the 3 variables and many more)
~30+ total variables
```

✅ **Pass:** New deployment variables are defined

## Script Testing

### 1. Test wait_for_instances.sh Syntax

```bash
cd infra/scripts

# Check shell script syntax
bash -n wait_for_instances.sh

# Check for required environment variables
grep "TARGET_GROUP_ARN" wait_for_instances.sh
grep "AWS_REGION" wait_for_instances.sh
grep "TIMEOUT" wait_for_instances.sh
```

✅ **Pass:** Script syntax is valid

### 2. Test run_ansible_full.sh Syntax

```bash
cd infra/scripts

# Check for required functions
grep "ansible-playbook" run_ansible_full.sh
grep "boto3" run_ansible_full.sh
grep "log_level" run_ansible_full.sh
```

✅ **Pass:** Script contains expected patterns

### 3. Test deploy_traefik.sh Syntax

```bash
cd infra/scripts

# Check for Traefik-specific logic
grep "traefik" deploy_traefik.sh | head -5
grep "SSL" deploy_traefik.sh | head -3
```

✅ **Pass:** Script contains Traefik configuration

### 4. Test validate_deployment.sh Syntax

```bash
cd infra/scripts

# Check for health check logic
grep "curl" validate_deployment.sh
grep "health" validate_deployment.sh
```

✅ **Pass:** Script contains health check logic

### 5. Test deployment_summary.sh Syntax

```bash
cd infra/scripts

# Check for summary output
grep "DEPLOYMENT SUMMARY" deployment_summary.sh
```

✅ **Pass:** Script contains summary output

## Documentation Verification

### 1. Check SINGLE_COMMAND_DEPLOYMENT.md

```bash
cd infra

# Check file exists and has content
wc -l SINGLE_COMMAND_DEPLOYMENT.md

# Check key sections
grep -c "## " SINGLE_COMMAND_DEPLOYMENT.md

# Verify content covers all stages
grep -i "stage" SINGLE_COMMAND_DEPLOYMENT.md | wc -l
```

**Expected Output:**

```
800+ lines
15+ sections
Multiple stage references
```

✅ **Pass:** Comprehensive documentation exists

### 2. Check SINGLE_COMMAND_QUICK_REFERENCE.md

```bash
cd infra

# Check file exists
ls -lh SINGLE_COMMAND_QUICK_REFERENCE.md

# Check for quick command
grep "terraform apply -auto-approve" SINGLE_COMMAND_QUICK_REFERENCE.md
```

✅ **Pass:** Quick reference guide exists and contains main command

### 3. Check DEPLOYMENT_CHECKLIST.md

```bash
cd infra

# Check checklist items
grep "^\- \[ \]" DEPLOYMENT_CHECKLIST.md | wc -l
```

**Expected Output:**

```
100+ checklist items
```

✅ **Pass:** Comprehensive checklist exists

## Integration Testing

### 1. Verify Terraform State Handling

```bash
cd infra

# Check if state files would be created in correct location
# (Backend should be configured)
cat backend-config.hcl | grep bucket
```

**Expected Output:**

```
bucket = "devops-stage-6-terraform-state"
```

✅ **Pass:** Backend configuration exists

### 2. Verify Dependency Order

```bash
cd infra

# Check dependencies in deployment.tf
grep "depends_on" deployment.tf | wc -l

# Verify trigger configurations
grep "triggers" deployment.tf | wc -l
```

**Expected Output:**

```
Multiple depends_on entries
Multiple trigger configurations
```

✅ **Pass:** Dependencies are properly configured

### 3. Verify Environment Variables

```bash
cd infra

# Check scripts use environment variables
grep "environment\|export" scripts/run_ansible_full.sh | wc -l
grep "environment\|export" scripts/wait_for_instances.sh | wc -l
grep "environment\|export" scripts/deploy_traefik.sh | wc -l
```

**Expected Output:**

```
Multiple environment variable references in each script
```

✅ **Pass:** Scripts properly use environment variables

## Feature Verification

### 1. Verify Idempotency Markers

```bash
cd infra

# Check for changed_when markers in Ansible tasks
grep -r "changed_when" playbooks/ | wc -l

# Check for when conditions
grep -r "when:" playbooks/ | wc -l
```

**Expected Output:**

```
Multiple idempotent markers
```

✅ **Pass:** Playbooks include idempotency markers

### 2. Verify Error Handling

```bash
cd infra/scripts

# Check for error handling in scripts
grep -c "set -e" *.sh
grep -c "|| " *.sh
grep -c "if \[" *.sh
grep -c "exit 1" *.sh
```

✅ **Pass:** Scripts contain error handling

### 3. Verify Logging

```bash
cd infra/scripts

# Check for logging functions
grep -c "log_level" *.sh
grep -c "echo\|print" *.sh
```

✅ **Pass:** Scripts include logging

### 4. Verify Health Checks

```bash
cd infra/scripts

# Check for health check implementation
grep -c "health" validate_deployment.sh
grep -c "curl" validate_deployment.sh
grep -c "retry" validate_deployment.sh
```

✅ **Pass:** Health checks are implemented

## Readiness Checklist

Before running actual deployment, verify:

- [ ] `terraform validate` passes
- [ ] All scripts are executable
- [ ] All documentation files exist
- [ ] AWS credentials are valid
- [ ] `terraform plan` shows expected resources
- [ ] All required tools are installed
- [ ] `terraform.tfvars` is configured
- [ ] Backend is initialized
- [ ] No Terraform locks are stuck
- [ ] SSH key is available locally

## Post-Deployment Verification (After Running)

### 1. Verify Infrastructure Created

```bash
# Check if resources exist in AWS
aws ec2 describe-vpcs --query 'Vpcs[?Tags[?Key==`Name`]].VpcId'
aws ec2 describe-instances --query 'Reservations[].Instances[].InstanceId'
aws elbv2 describe-load-balancers --query 'LoadBalancers[].LoadBalancerArn'
```

### 2. Verify Ansible Inventory

```bash
cd infra
cat inventory/hosts.ini
```

**Expected Format:**

```
[all_instances]
instance-1 ansible_host=10.0.2.x
instance-2 ansible_host=10.0.2.y

[all_instances:vars]
ansible_user=ec2-user
ansible_python_interpreter=/usr/bin/python3
```

### 3. Verify Terraform Outputs

```bash
cd infra
terraform output
```

**Expected Outputs:**

```
alb_dns_name = "app-xxxxx.elb.amazonaws.com"
vpc_id = "vpc-xxxxx"
asg_name = "devops-stage-6-asg"
(+ more)
```

### 4. Verify Application Accessibility

```bash
# Get ALB DNS from terraform outputs
ALB_DNS=$(cd infra && terraform output -raw alb_dns_name)

# Test connectivity
curl -v http://$ALB_DNS/

# Check HTTP status
curl -o /dev/null -s -w "%{http_code}\n" http://$ALB_DNS/
```

**Expected Output:**

```
HTTP/1.1 200 OK
(or 200 status code)
```

## Success Indicators

✅ **All Verification Steps Pass:**

1. Files are in place and executable
2. Terraform configuration is valid
3. All required tools are installed
4. Scripts have correct syntax
5. Documentation is comprehensive
6. Dependencies are properly configured
7. Error handling is implemented
8. Logging is functional
9. Health checks are in place
10. Infrastructure deploys successfully

## Troubleshooting Verification

If verification fails, check:

### Terraform Errors

```bash
cd infra
terraform validate
TF_LOG=DEBUG terraform plan
```

### Script Errors

```bash
bash -x scripts/wait_for_instances.sh
bash -x scripts/run_ansible_full.sh
```

### AWS Errors

```bash
aws sts get-caller-identity
aws ec2 describe-instances
aws ec2 describe-security-groups
```

## Final Verification Command

Run all checks at once:

```bash
#!/bin/bash

cd /home/nayo/stage-6/DevOps-Stage-6/infra

echo "=== Terraform Validation ==="
terraform validate && echo "✓ PASS" || echo "✗ FAIL"

echo -e "\n=== Script Syntax Check ==="
for script in scripts/*.sh; do
    bash -n "$script" && echo "✓ $script" || echo "✗ $script"
done

echo -e "\n=== Documentation Check ==="
test -f SINGLE_COMMAND_DEPLOYMENT.md && echo "✓ PASS" || echo "✗ FAIL"
test -f SINGLE_COMMAND_QUICK_REFERENCE.md && echo "✓ PASS" || echo "✗ FAIL"
test -f DEPLOYMENT_CHECKLIST.md && echo "✓ PASS" || echo "✗ FAIL"

echo -e "\n=== AWS Credentials Check ==="
aws sts get-caller-identity > /dev/null && echo "✓ PASS" || echo "✗ FAIL"

echo -e "\n=== Dependencies Check ==="
command -v terraform && echo "✓ Terraform" || echo "✗ Terraform"
command -v aws && echo "✓ AWS CLI" || echo "✗ AWS CLI"
command -v ansible-playbook && echo "✓ Ansible" || echo "✗ Ansible"

echo -e "\n=== All Checks Complete ==="
```

## Conclusion

This verification guide ensures that the single-command deployment implementation is complete, correct, and ready for use. All verification steps should pass before attempting an actual deployment.

For any failures, refer to the troubleshooting sections in this guide or the main documentation files.
