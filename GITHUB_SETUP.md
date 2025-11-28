# GitHub Actions - Environment & Secrets Setup Guide

## 📋 Required Secrets Configuration

Navigate to: **GitHub Repository > Settings > Secrets and variables > Actions**

### 1. AWS_ROLE_TO_ASSUME

**Type**: Repository Secret
**Purpose**: IAM role for GitHub Actions OIDC federation

```
arn:aws:iam::YOUR_AWS_ACCOUNT_ID:role/github-actions-role
```

**How to create**:

1. Go to AWS IAM Console
2. Create new role with trusted entity: Web identity (OpenID Connect provider)
3. Select provider: `token.actions.githubusercontent.com`
4. Audience: `sts.amazonaws.com`
5. Attach policies: `AdministratorAccess` (or more restrictive)
6. Copy role ARN

### 2. ALERT_EMAIL

**Type**: Repository Secret
**Purpose**: Email recipient for infrastructure alerts

```
your-email@example.com
```

### 3. SES_EMAIL_FROM

**Type**: Repository Secret
**Purpose**: AWS SES sender email (must be verified in SES)

```
noreply@example.com
```

**How to configure**:

1. Go to AWS SES Console
2. Verify email address or domain
3. Request production access
4. Use verified email in this secret

### 4. SLACK_WEBHOOK (Optional)

**Type**: Repository Secret
**Purpose**: Slack webhook for notifications

```
https://hooks.slack.com/services/YOUR/WEBHOOK/URL
```

**How to create**:

1. Go to Slack App Configuration
2. Navigate to "Incoming Webhooks"
3. Create New Webhook
4. Select channel
5. Copy webhook URL

## 🔐 Environment Configuration

Navigate to: **GitHub Repository > Settings > Environments**

### Development Environment

**Name**: `dev-approval`

```
Deployment branches and tags: All branches
Wait timer: 0 minutes
Reviewers: (optional)
Protected branches: No
Environment secrets: (none required)
```

**Name**: `dev-deploy`

```
Deployment branches and tags: All branches
Reviewers: (optional)
```

### Staging Environment

**Name**: `staging-approval`

```
Deployment branches and tags: main, develop
Wait timer: 5 minutes
Reviewers: (required) @devops-team
Protected branches: Yes (main)
```

**Name**: `staging-deploy`

```
Deployment branches and tags: main, develop
Reviewers: (required) @devops-team
Environment secrets:
  - ENVIRONMENT: staging
  - DEBUG_MODE: false
```

### Production Environment

**Name**: `prod-approval`

```
Deployment branches and tags: main
Wait timer: 15 minutes
Reviewers: (required) @devops-leads
Protected branches: Yes (main)
Deployment sources: GitHub Actions (workflows)
```

**Name**: `prod-deploy`

```
Deployment branches and tags: main
Reviewers: (required) @devops-leads
Environment secrets:
  - ENVIRONMENT: prod
  - DEBUG_MODE: false
  - PRODUCTION: true
```

## 🔗 AWS OIDC Setup

### Step 1: Create OIDC Provider in AWS IAM

```bash
# Using AWS CLI
aws iam create-open-id-connect-provider \
  --url https://token.actions.githubusercontent.com \
  --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
  --client-id-list sts.amazonaws.com
```

**Output**: Note the provider ARN

```
arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com
```

### Step 2: Create IAM Role

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:greatnayo/DevOps-Stage-6:*"
        }
      }
    }
  ]
}
```

### Step 3: Attach Required Policies

**For Infrastructure (Terraform & Ansible)**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "s3:*",
        "iam:*",
        "rds:*",
        "elasticache:*",
        "cloudformation:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "secretsmanager:GetSecretValue"
      ],
      "Resource": "arn:aws:ssm:*:123456789012:parameter/*"
    }
  ]
}
```

**For Application Deployment**:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeTags",
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["ses:SendEmail"],
      "Resource": "*"
    }
  ]
}
```

## 📧 AWS SES Configuration

### Step 1: Verify Email/Domain

```bash
# Verify single email
aws ses verify-email-identity --email-address noreply@example.com

# Or verify domain
aws ses verify-domain-identity --domain example.com
```

### Step 2: Set Sending Quota

```bash
# Request production access (starts in sandbox)
# Go to AWS SES Console > Settings > Request Production Access
```

### Step 3: Store Configuration

- Store sender email in `SES_EMAIL_FROM` secret
- Store recipient in `ALERT_EMAIL` secret

## 🔔 Testing Secrets Configuration

### Validate Secrets Are Set

Create a test workflow file `.github/workflows/test-secrets.yml`:

```yaml
name: Test Secrets

on:
  workflow_dispatch:

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - name: Check secrets
        run: |
          if [ -z "${{ secrets.AWS_ROLE_TO_ASSUME }}" ]; then
            echo "❌ AWS_ROLE_TO_ASSUME not set"
            exit 1
          fi
          if [ -z "${{ secrets.ALERT_EMAIL }}" ]; then
            echo "❌ ALERT_EMAIL not set"
            exit 1
          fi
          if [ -z "${{ secrets.SES_EMAIL_FROM }}" ]; then
            echo "❌ SES_EMAIL_FROM not set"
            exit 1
          fi
          echo "✅ All required secrets are configured"
```

## 📋 Pre-Deployment Checklist

Before deploying for the first time:

### GitHub Configuration

- [ ] All 4 repository secrets configured
- [ ] AWS_ROLE_TO_ASSUME tested with OIDC
- [ ] Environments created (dev, staging, prod)
- [ ] Approval reviewers assigned
- [ ] Branch protection enabled for main

### AWS Configuration

- [ ] OIDC provider created
- [ ] IAM role created with policies
- [ ] S3 backend bucket for Terraform
- [ ] SES email verified and in production mode
- [ ] EC2 instances tagged for inventory
- [ ] Security groups configured

### Ansible Configuration

- [ ] SSH key pair created and stored
- [ ] EC2 instances have public IP/DNS
- [ ] Security group allows port 22 (SSH)
- [ ] EC2 user can run docker commands
- [ ] inventory script can generate hosts

### Workflow Testing

- [ ] Validation script passes
- [ ] Test secrets workflow succeeds
- [ ] Manual push to main triggers workflow
- [ ] Drift detection runs successfully
- [ ] Email alerts are received
- [ ] Approval gate functions properly

## 🔄 Workflow Variables

### Environment Variables

Set in workflow file under `env:` or in environment configuration:

```yaml
env:
  AWS_REGION: us-east-1
  TERRAFORM_VERSION: "1.6.0"
  REGISTRY: ghcr.io
```

### Passing Variables Between Jobs

Use `outputs` to pass data:

```yaml
jobs:
  job1:
    outputs:
      output_var: ${{ steps.step1.outputs.output_var }}
    steps:
      - id: step1
        run: echo "output_var=value" >> $GITHUB_OUTPUT

  job2:
    needs: job1
    runs-on: ubuntu-latest
    steps:
      - run: echo "Value is ${{ needs.job1.outputs.output_var }}"
```

## 🔐 Security Best Practices

1. **Use OIDC Federation** instead of personal access tokens
2. **Rotate Secrets** regularly (every 90 days)
3. **Limit Secret Access** to specific branches/environments
4. **Monitor Secret Usage** in workflow logs
5. **Never Log Secrets** in workflow output
6. **Use Temporary Credentials** with expiration
7. **Review Environment Protection Rules** regularly
8. **Audit Approver Access** periodically

## 📊 Workflow Permissions

Required GitHub token permissions:

```yaml
permissions:
  contents: read # Read repository contents
  pull-requests: write # Comment on PRs
  issues: write # Create issues
  id-token: write # For OIDC
```

## 🆘 Troubleshooting Setup

### AWS_ROLE_TO_ASSUME Not Found

```
Error: User: arn:aws:sts::ACCOUNT:assumed-role/... is not authorized
```

**Solution**:

- Verify role ARN is correct
- Check trust relationship policy
- Ensure OIDC provider is configured

### Email Not Sending

```
Error: MessageRejected - Email address not verified in SES
```

**Solution**:

- Verify email in AWS SES console
- Check SES_EMAIL_FROM matches verified email
- Ensure SES is in production mode

### SSH Connection Refused

```
Error: ssh: connect to host ... port 22: Connection refused
```

**Solution**:

- Check security group allows port 22
- Verify EC2 instance is running
- Confirm SSH key permissions (chmod 600)

### Inventory Empty

```
Error: No instances found matching the provided filter
```

**Solution**:

- Verify EC2 tags match inventory script
- Check IAM permissions for ec2:DescribeInstances
- Ensure instances are in correct region

## 📞 Support Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [AWS OIDC Provider](https://docs.github.com/actions/deployment/security-hardening-your-deployments/about-security-hardening-with-openid-connect)
- [AWS SES Setup](https://docs.aws.amazon.com/ses/latest/dg/send-email.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

---

**Last Updated**: November 28, 2025
**Version**: 1.0
