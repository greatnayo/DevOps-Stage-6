# CI/CD Setup - Quick Reference

## ✅ Implementation Checklist

### Ansible Roles Created

- [x] `dependencies/` role - Docker, Docker Compose, Git, Traefik prerequisites
- [x] `deploy/` role - Application cloning, deployment, Traefik setup, SSL
- [x] Updated `site.yml` to use roles instead of inline tasks

### CI/CD Workflows Created

- [x] `infra-terraform-ansible.yml` - Infrastructure provisioning and server setup
- [x] `app-deploy-services.yml` - Service building and deployment
- [x] `scheduled-drift-detection.yml` - Continuous drift monitoring (6-hour schedule)
- [x] `send-email.yml` - Email notification helper workflow

### Drift Detection Features

- [x] Terraform plan comparison against current state
- [x] Automatic issue creation for detected drift
- [x] Email notifications on drift detection
- [x] Slack notifications (optional)
- [x] Approval gate for manual review
- [x] Auto-apply when no drift detected
- [x] Scheduled checks every 6 hours

### Required Secrets to Configure

```bash
# GitHub > Settings > Secrets and variables > Actions > New repository secret

AWS_ROLE_TO_ASSUME          # AWS IAM role ARN for OIDC
ALERT_EMAIL                 # Email for alerts
SES_EMAIL_FROM              # AWS SES sender email
SLACK_WEBHOOK               # (Optional) Slack webhook URL
```

## 📋 File Locations

```
New Files Created:
├── .github/workflows/
│   ├── infra-terraform-ansible.yml      (650+ lines)
│   ├── app-deploy-services.yml          (600+ lines)
│   ├── scheduled-drift-detection.yml    (300+ lines)
│   └── send-email.yml                   (60 lines)
│
├── infra/playbooks/
│   ├── site.yml                         (UPDATED - now uses roles)
│   └── roles/
│       ├── dependencies/
│       │   ├── tasks/main.yml           (120 lines)
│       │   ├── handlers/main.yml        (15 lines)
│       │   └── defaults/main.yml        (10 lines)
│       │
│       └── deploy/
│           ├── tasks/main.yml           (230 lines)
│           ├── handlers/main.yml        (20 lines)
│           ├── defaults/main.yml        (45 lines)
│           └── templates/
│               ├── docker-compose.env.j2
│               ├── traefik-config.yml.j2
│               └── traefik-routing.yml.j2
│
└── CICD_GUIDE.md                        (Comprehensive documentation)
```

## 🚀 How to Use

### Trigger Infrastructure Workflow

```
Event: Push changes to infra/terraform/** or infra/ansible/**
Branch: main or develop
Trigger: Automatic via GitHub Actions
```

### Trigger App Deployment Workflow

```
Event: Push changes to any service folder or docker-compose.yml
Branch: main or develop
Trigger: Automatic via GitHub Actions
```

### Manual Workflow Trigger

1. Go to **GitHub Actions**
2. Select workflow
3. Click **Run workflow**
4. Choose branch and options

## 🔄 Workflow Behavior Matrix

| Scenario             | Terraform Plan | Drift Detection | Approval Required | Apply Auto?   |
| -------------------- | -------------- | --------------- | ----------------- | ------------- |
| No changes           | ✓              | ✗               | ✗                 | -             |
| Changes found        | ✓              | ✓               | ✓                 | ✗             |
| Approved after drift | ✓              | ✓               | ✓                 | ✓             |
| Dev branch push      | ✓              | -               | -                 | ✗ (main only) |

## 📊 Service Build & Deploy

**Services automatically built and deployed:**

1. Auth API (Go)
2. Todos API (Node.js)
3. Users API (Java)
4. Frontend (Vue.js)
5. Log Message Processor (Python)

**Change Detection:**

- Only builds services with changes
- Skips if no code modifications
- Runs all if docker-compose.yml changes

## 🔐 Approval Gate Flow

```
Terraform Plan
    ↓
    ├─ No Drift → Apply Auto
    │
    └─ Drift Detected
        ├─ Create GitHub Issue
        ├─ Send Email Alert
        ├─ Pause Workflow
        ├─ Wait for Approval
        └─ After Approval → Apply
```

## 📧 Notifications

### Email Alerts Sent On:

- ✓ Infrastructure drift detected
- ✓ Deployment failures
- ✓ Health check failures
- ✓ Manual approval required

### GitHub Issues Created For:

- ✓ Infrastructure drift (auto-updated)
- ✓ Deployment failures
- ✓ Health check failures

### Slack Alerts (Optional):

- ✓ Drift detection
- ✓ Deployment status
- ✓ Critical failures

## 🛠️ Manual Operations

### Check Drift Manually

```bash
cd infra/scripts
bash check-drift.sh
```

### Run Ansible Locally

```bash
cd infra/playbooks
ansible-playbook site.yml -i ../scripts/inventory --tags dependencies,deploy
```

### Generate Inventory

```bash
cd infra/scripts
bash generate_inventory.sh dev
```

## ✨ Key Features

### Idempotent Deployment

- Services only restart if files changed
- No unnecessary downtime
- Tracks changes via git diff

### Intelligent Change Detection

- Analyzes which services changed
- Skips unchanged services
- Parallel builds for efficiency

### Drift Management

- Continuous monitoring (6-hour schedule)
- Auto-remediation available
- Manual approval for safety

### Health Checks

- Post-deployment validation
- Endpoint status verification
- Automatic rollback on failure

### Traceability

- Links workflow runs to commits
- Tracks all deployments
- Audit trail of changes

## 🔗 Related Documentation

- **Infrastructure Guide**: See `ENVIRONMENT.md`
- **Terraform Documentation**: See `infra/README.md`
- **Ansible Playbooks**: See `infra/playbooks/`
- **Service README Files**: See individual service folders

## ⚠️ Important Notes

1. **AWS IAM Role**: Configure OIDC federation for GitHub Actions
2. **Email Configuration**: Set up AWS SES and configure sender email
3. **Inventory Generation**: Requires EC2 instances to be tagged properly
4. **Ansible SSH**: Ensure EC2 key pair is accessible to workflow runner
5. **State Management**: Terraform state files stored in S3 backend

## 🔄 Next Steps

1. Configure GitHub secrets
2. Update Terraform backend configuration
3. Tag EC2 instances for inventory discovery
4. Test workflow manually via `workflow_dispatch`
5. Monitor first automated run
6. Adjust approval gates as needed
7. Enable Slack notifications (optional)

## 📞 Troubleshooting

**Workflow fails at AWS step?**

- Verify AWS_ROLE_TO_ASSUME secret
- Check IAM role trust relationship with GitHub OIDC

**Ansible cannot reach servers?**

- Verify EC2 security groups allow SSH
- Check instance tags match inventory generation
- Ensure EC2 key pair is configured

**Docker build fails?**

- Check registry credentials
- Verify Dockerfile paths
- Review build logs in workflow

**Drift detection not working?**

- Verify Terraform backend is configured
- Check IAM permissions for state file access
- Ensure all required Terraform vars are set

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Ansible Documentation](https://docs.ansible.com)
- [AWS ECS/EC2 Best Practices](https://docs.aws.amazon.com/ec2)
