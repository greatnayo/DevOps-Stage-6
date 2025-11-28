# CI/CD Pipeline Automation Guide

## Overview

This repository includes a comprehensive CI/CD pipeline with automated infrastructure deployment, server setup, and application deployment. The pipeline is built on GitHub Actions and includes intelligent change detection, drift management, and approval workflows.

## Architecture

### Workflows

#### 1. **Infrastructure Workflow** (`infra-terraform-ansible.yml`)

Handles infrastructure provisioning and server setup automation.

**Triggers:**

- Push to `main` or `develop` branches when `infra/terraform/**` or `infra/ansible/**` changes
- Manual trigger via workflow dispatch

**Pipeline Steps:**

1. **Terraform Plan & Drift Detection**

   - Initializes Terraform backend
   - Runs format and validation checks
   - Generates Terraform plan
   - Compares current state with desired state to detect drift

2. **Drift Notification**

   - Creates GitHub issue if drift is detected
   - Sends email alerts to configured recipients

3. **Approval Gate**

   - Pauses for manual approval if drift is detected
   - Allows automatic apply if no drift

4. **Terraform Apply**

   - Applies infrastructure changes only on `main` branch
   - Auto-approves if no drift detected
   - Saves outputs for downstream jobs

5. **Ansible Validation**

   - Syntax checking of playbooks
   - Linting with ansible-lint

6. **Ansible Deployment**
   - Generates dynamic inventory from AWS EC2 instances
   - Installs dependencies (Docker, Docker Compose, Git, etc.)
   - Deploys applications to servers
   - Runs post-deployment health checks

#### 2. **Application Deployment Workflow** (`app-deploy-services.yml`)

Handles building, testing, and deploying services.

**Triggers:**

- Push to `main` or `develop` when service code or `docker-compose.yml` changes
- Manual trigger via workflow dispatch

**Pipeline Steps:**

1. **Change Detection**

   - Analyzes which services changed
   - Sets flags for downstream jobs

2. **Build & Test** (Parallel for each service)

   - **Auth API** (Go): Build and push Docker image
   - **Todos API** (Node.js): Build and push Docker image
   - **Users API** (Java): Build and push Docker image
   - **Frontend** (Vue.js): Build and push Docker image
   - **Log Processor** (Python): Build and push Docker image

3. **Application Deployment**

   - Updates docker-compose.yml with new image tags
   - Runs Ansible playbook to deploy services
   - Performs health checks on all endpoints

4. **Rollback on Failure**
   - Creates issue and notifies team on deployment failure

#### 3. **Scheduled Drift Detection** (`scheduled-drift-detection.yml`)

Runs every 6 hours to detect infrastructure drift.

**Features:**

- Checks all environments (dev, staging, prod)
- Creates/updates GitHub issues for drift
- Sends email alerts
- Posts to Slack (if configured)

## Required Secrets

Configure these secrets in your GitHub repository settings:

| Secret Name          | Description                     | Example                                         |
| -------------------- | ------------------------------- | ----------------------------------------------- |
| `AWS_ROLE_TO_ASSUME` | AWS IAM role for GitHub OIDC    | `arn:aws:iam::123456789012:role/github-actions` |
| `ALERT_EMAIL`        | Email for infrastructure alerts | `devops@example.com`                            |
| `SES_EMAIL_FROM`     | AWS SES sender email            | `noreply@example.com`                           |
| `SLACK_WEBHOOK`      | Slack webhook URL (optional)    | `https://hooks.slack.com/...`                   |
| `GITHUB_TOKEN`       | GitHub token (auto-provided)    | Auto-generated                                  |

## Ansible Roles

### Role: `dependencies`

Installs all required dependencies on target servers.

**Tasks:**

- Update system packages
- Install Docker and Docker Compose
- Install common tools (git, curl, wget, jq, python3)
- Install Traefik prerequisites
- Create Docker network
- Enable Docker service

**Variables:**

- `force_docker_compose_update`: Force Docker Compose update (default: false)
- `traefik_email`: Email for Let's Encrypt (default: admin@example.com)

### Role: `deploy`

Handles application deployment and Traefik configuration.

**Tasks:**

- Clone/update application repository
- Create environment files
- Pull latest Docker images
- Deploy services with docker-compose (idempotent)
- Setup Traefik configuration
- Configure SSL/TLS certificates
- Health checks

**Key Features:**

- **Idempotent Deployment**: Services only restart if files changed
- **Change Tracking**: Tracks git changes and configuration updates
- **Automatic Health Checks**: Validates service endpoints
- **SSL Automation**: Integrates with Let's Encrypt

**Variables:**

- `app_directory`: Application directory (default: /opt/app)
- `app_repo_url`: Git repository URL
- `app_branch`: Git branch to deploy (default: main)
- `environment`: Deployment environment (dev, staging, prod)
- `setup_traefik`: Enable Traefik setup (default: true)
- `setup_ssl`: Enable SSL/TLS (default: true)
- `domain`: Domain for SSL certificates (default: localhost)

## File Structure

```
.github/workflows/
├── infra-terraform-ansible.yml      # Infrastructure workflow
├── app-deploy-services.yml          # Application deployment workflow
├── scheduled-drift-detection.yml    # Scheduled drift detection
└── send-email.yml                   # Email notification helper

infra/
├── playbooks/
│   ├── site.yml                     # Main playbook (uses roles)
│   └── roles/
│       ├── dependencies/
│       │   ├── tasks/main.yml       # Dependency installation tasks
│       │   ├── handlers/main.yml    # Service restart handlers
│       │   └── defaults/main.yml    # Default variables
│       └── deploy/
│           ├── tasks/main.yml       # Deployment tasks
│           ├── handlers/main.yml    # Deployment handlers
│           ├── templates/           # Traefik and env configurations
│           └── defaults/main.yml    # Default variables
├── scripts/
│   ├── generate_inventory.sh        # Generate Ansible inventory
│   ├── check-drift.sh               # Manual drift detection
│   └── run_ansible.sh               # Run playbook manually
└── terraform/                       # Terraform configurations
```

## Usage

### Manual Infrastructure Deployment

```bash
# Run Ansible playbook locally
cd infra/playbooks
ansible-playbook site.yml -i ../scripts/inventory --tags dependencies,deploy

# Check infrastructure drift
cd infra/scripts
bash check-drift.sh --auto-approve

# Deploy only dependencies
cd infra/playbooks
ansible-playbook site.yml -i ../scripts/inventory --tags dependencies
```

### Manual Application Deployment

```bash
# Push to main branch to trigger deployment
git push origin main

# Or trigger workflow manually via GitHub UI
# Navigate to Actions > App Deployment - Services > Run workflow
```

### Check Workflow Status

1. Navigate to **Actions** tab in GitHub
2. Select the workflow to view
3. Click on a run to see details

### Required Environment Variables

For local execution, set these environment variables:

```bash
export AWS_REGION=us-east-1
export TF_VAR_environment=dev
export ANSIBLE_HOST_KEY_CHECKING=false
```

## Workflow Triggers and Conditions

### Infrastructure Workflow Triggers

| Trigger                      | Condition          | Action                 |
| ---------------------------- | ------------------ | ---------------------- |
| `infra/terraform/**` changes | Any branch         | Plan only              |
| `infra/terraform/**` changes | `main` branch push | Plan → Approve → Apply |
| `infra/ansible/**` changes   | Any branch         | Syntax check           |
| Manual dispatch              | Any branch         | Plan or Apply          |

### Application Workflow Triggers

| Trigger                      | Condition           | Action                   |
| ---------------------------- | ------------------- | ------------------------ |
| Service code changes         | `main` branch push  | Build → Test → Deploy    |
| `docker-compose.yml` changes | `main` branch push  | Deploy                   |
| Pull request                 | Any service changes | Build → Test (no deploy) |
| Manual dispatch              | Any branch          | Build all → Deploy       |

## Approval Workflows

### Infrastructure Approval Gate

1. **Drift Detected**

   - Workflow pauses at approval stage
   - GitHub issue created with details
   - Email alert sent to team
   - Requires manual approval to continue

2. **No Drift**
   - Terraform apply runs automatically
   - Ansible deployment proceeds

### Application Deployment

- Automatic on `main` branch push if code changed
- No approval required (can be added via environment protection rules)

## Health Checks

Both workflows include health checks:

**Infrastructure Workflow:**

- Waits 30 seconds for services to stabilize
- Validates application endpoints
- Reports health status

**Application Workflow:**

- Frontend: `GET /`
- Auth API: `GET /auth/health`
- Todos API: `GET /todos/health`
- Users API: `GET /users/health`

## Monitoring and Alerts

### Email Alerts

- Infrastructure drift detected
- Deployment failures
- Health check failures

### GitHub Issues

- Auto-created for drift detection
- Tagged with environment and service labels
- Linked to workflow runs

### Optional Slack Integration

- Drift detection alerts
- Deployment status
- Health check failures

Configure webhook URL in `SLACK_WEBHOOK` secret.

## Troubleshooting

### Workflow Failures

1. **Check workflow logs**

   - Go to Actions > Failed workflow > View logs

2. **Common issues:**
   - AWS credentials not configured: Check IAM role and OIDC configuration
   - SSH key access: Verify private key is in agent or SSH config
   - Docker image pull: Check image repository and credentials
   - Ansible inventory: Verify AWS instances are running and tagged

### Manual Recovery

```bash
# SSH into server and check Docker status
ssh -i key.pem ec2-user@instance-ip
docker-compose ps
docker-compose logs -f

# Manually pull latest changes
cd /opt/app
git pull origin main
docker-compose pull
docker-compose up -d
```

### Rerun Workflows

1. Navigate to Actions tab
2. Click on failed workflow
3. Click "Re-run jobs" or "Re-run all jobs"

## Best Practices

1. **Commit to feature branches** and create PRs before merging to main
2. **Use environments** to protect sensitive deployments
3. **Review drift reports** before approving infrastructure changes
4. **Monitor health checks** in workflow logs
5. **Keep secrets rotated** and use IAM roles where possible
6. **Tag resources** in Terraform for tracking
7. **Document configuration** in README files
8. **Test locally** before pushing to main

## Performance Optimization

- Workflows use parallel jobs for build steps
- Change detection prevents unnecessary rebuilds
- Artifacts cached in GitHub Actions
- Terraform state locked to prevent conflicts

## Security Considerations

- AWS credentials via OIDC federation
- Secrets stored in GitHub encrypted storage
- SSH key validation for Git operations
- Docker registry authentication
- Ansible playbooks validated before execution
- Approval gates for production changes

## Support and Contributions

For issues or improvements:

1. Create a GitHub issue with details
2. Include workflow logs and error messages
3. Propose solutions or enhancements
4. Submit pull requests for review
