# Infrastructure Code - File Index & Documentation Map

This is your complete guide to all files in the `infra/` directory.

## 📚 Documentation Files (Start Here!)

### Getting Started

| File                                       | Purpose                                         | Read Time |
| ------------------------------------------ | ----------------------------------------------- | --------- |
| [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) | **⭐ START HERE** - Common commands cheat sheet | 5 min     |
| [QUICKSTART.md](./QUICKSTART.md)           | 5-step deployment guide                         | 10 min    |
| [README.md](./README.md)                   | Complete infrastructure guide with examples     | 30 min    |

### Configuration & Operations

| File                                                     | Purpose                               | Read Time |
| -------------------------------------------------------- | ------------------------------------- | --------- |
| [VARIABLES.md](./VARIABLES.md)                           | Variables reference with examples     | 15 min    |
| [DRIFT_DETECTION.md](./DRIFT_DETECTION.md)               | Drift detection setup and usage       | 20 min    |
| [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)     | Pre-deployment verification checklist | 10 min    |
| [IMPLEMENTATION_SUMMARY.md](./IMPLEMENTATION_SUMMARY.md) | What has been implemented             | 15 min    |

## 🏗️ Terraform Configuration Files

### Core Infrastructure

| File                                       | Contains              | Resources                                                   |
| ------------------------------------------ | --------------------- | ----------------------------------------------------------- |
| [main.tf](./main.tf)                       | **Primary resources** | VPC, subnets, IGW, NAT, ALB, ASG, EC2, IAM, Security Groups |
| [variables.tf](./variables.tf)             | Input variables       | 12 variables with validation                                |
| [outputs.tf](./outputs.tf)                 | Output values         | 13 outputs (DNS, IDs, ARNs)                                 |
| [backend.tf](./backend.tf)                 | State backend config  | S3 + DynamoDB setup                                         |
| [backend-config.hcl](./backend-config.hcl) | Backend parameters    | S3 bucket, DynamoDB table                                   |

### Configuration Examples

| File                                                   | Purpose               | Usage                                          |
| ------------------------------------------------------ | --------------------- | ---------------------------------------------- |
| [terraform.tfvars.example](./terraform.tfvars.example) | Example configuration | `cp terraform.tfvars.example terraform.tfvars` |

### Bootstrap & Provisioning

| File                           | Purpose                | Runs On          |
| ------------------------------ | ---------------------- | ---------------- |
| [user_data.sh](./user_data.sh) | EC2 instance bootstrap | Instance startup |

## ⚙️ Ansible Playbooks

| File                                                                             | Purpose                                                      | When Runs              |
| -------------------------------------------------------------------------------- | ------------------------------------------------------------ | ---------------------- |
| [playbooks/site.yml](./playbooks/site.yml)                                       | **Main playbook** - Installs services, configures monitoring | After Terraform apply  |
| [playbooks/roles/common/tasks/main.yml](./playbooks/roles/common/tasks/main.yml) | **Common tasks** - Docker, Docker Compose, Python            | Via site.yml           |
| [templates/inventory.tpl](./templates/inventory.tpl)                             | **Inventory template** - Generates hosts file                | Terraform provisioning |

## 🔄 Automation Scripts

### Drift Detection & Monitoring

| File                                               | Purpose                                            | Usage                                        |
| -------------------------------------------------- | -------------------------------------------------- | -------------------------------------------- |
| [scripts/check-drift.sh](./scripts/check-drift.sh) | **Drift detection** - Finds infrastructure changes | `bash scripts/check-drift.sh`                |
| [scripts/check-drift.sh](./scripts/check-drift.sh) | Auto-approve mode                                  | `bash scripts/check-drift.sh --auto-approve` |

### Infrastructure Setup

| File                                                             | Purpose                                 | Usage                                |
| ---------------------------------------------------------------- | --------------------------------------- | ------------------------------------ |
| [scripts/setup-backend.sh](./scripts/setup-backend.sh)           | **Backend init** - Create S3 & DynamoDB | `bash scripts/setup-backend.sh`      |
| [scripts/generate_inventory.sh](./scripts/generate_inventory.sh) | Dynamic inventory                       | `bash scripts/generate_inventory.sh` |
| [scripts/run_ansible.sh](./scripts/run_ansible.sh)               | Ansible execution                       | Called by Terraform                  |

### Email Notifications

| File                                                 | Purpose               | Usage                                                         |
| ---------------------------------------------------- | --------------------- | ------------------------------------------------------------- |
| [scripts/send_via_ses.sh](./scripts/send_via_ses.sh) | AWS SES email sending | `bash scripts/send_via_ses.sh email@example.com subject body` |
| [scripts/notify-drift.sh](./scripts/notify-drift.sh) | Local notifications   | `bash scripts/notify-drift.sh email@example.com status`       |

### GitHub Actions Integration

| File                                                                   | Purpose                  | Usage                    |
| ---------------------------------------------------------------------- | ------------------------ | ------------------------ |
| [scripts/send-email/action.yml](./scripts/send-email/action.yml)       | GitHub Action definition | GitHub Actions workflow  |
| [scripts/send-email/entrypoint.sh](./scripts/send-email/entrypoint.sh) | Action entry point       | Called by GitHub Actions |

## 🔀 CI/CD Workflow

| File                                                                                                 | Purpose                                                   | Trigger                          |
| ---------------------------------------------------------------------------------------------------- | --------------------------------------------------------- | -------------------------------- |
| [.github/workflows/terraform-drift-detection.yml](./.github/workflows/terraform-drift-detection.yml) | **Main CI/CD** - Drift detection, email, approval, deploy | Every 6 hours + On push + Manual |

## 📂 Generated Directories

| Directory     | Purpose                  | Created By       | Git Ignored |
| ------------- | ------------------------ | ---------------- | ----------- |
| `inventory/`  | Ansible inventory files  | Terraform        | Yes         |
| `.terraform/` | Terraform provider cache | `terraform init` | Yes         |
| `roles/`      | Ansible roles (if used)  | Manual           | No          |

## 🛠️ Helper Files

| File                       | Purpose                             | Usage       |
| -------------------------- | ----------------------------------- | ----------- |
| [Makefile](./Makefile)     | **Command shortcuts** - 40+ targets | `make help` |
| [.gitignore](./.gitignore) | Git ignore rules                    | Automatic   |

## 📋 Quick Navigation by Task

### "I want to..."

#### Deploy Infrastructure

1. Read: [QUICKSTART.md](./QUICKSTART.md)
2. Run: `make setup && make deploy`
3. Verify: `terraform output`

#### Change Configuration

1. Edit: `terraform.tfvars`
2. Review: `make plan`
3. Apply: `make deploy`

#### Scale Infrastructure

1. Edit: `asg_desired_capacity` in `terraform.tfvars`
2. Apply: `terraform apply -var='asg_desired_capacity=5'`
3. Check: `aws autoscaling describe-auto-scaling-groups`

#### Set Up Drift Detection

1. Read: [DRIFT_DETECTION.md](./DRIFT_DETECTION.md)
2. Add GitHub Secrets (AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, ALERT_EMAIL)
3. Workflow runs automatically every 6 hours

#### Fix Infrastructure Drift

1. Review email alert with changes
2. Go to GitHub Actions workflow
3. Review and approve changes
4. `terraform apply` runs automatically

#### Understand Architecture

1. Read: [README.md](./README.md) (Architecture section)
2. Review: [main.tf](./main.tf) (resource definitions)
3. Check: [outputs.tf](./outputs.tf) (infrastructure details)

#### Customize Variables

1. Copy: `cp terraform.tfvars.example terraform.tfvars`
2. Edit: `terraform.tfvars`
3. Review: [VARIABLES.md](./VARIABLES.md) for all options
4. Apply: `terraform apply`

#### Debug Issues

1. Run: `TF_LOG=DEBUG terraform plan`
2. Check: AWS CloudFormation Events console
3. View: EC2 user data logs
4. Read: [README.md](./README.md) Troubleshooting section

## 🔍 File Statistics

| Category          | Count   | Total Lines |
| ----------------- | ------- | ----------- |
| Terraform files   | 5       | ~1000       |
| Ansible playbooks | 2       | ~150        |
| Shell scripts     | 7       | ~500        |
| Documentation     | 8       | ~2500       |
| Configuration     | 3       | ~100        |
| **Total**         | **25+** | **~4250**   |

## 🚀 Common Workflows

### First Time Setup (15 min)

```
1. Configure AWS: aws configure
2. Setup backend: bash scripts/setup-backend.sh
3. Initialize: terraform init -backend-config=backend-config.hcl
4. Configure: cp terraform.tfvars.example terraform.tfvars && vim terraform.tfvars
5. Deploy: terraform apply
6. Verify: terraform output && curl http://alb-dns/health
```

### Regular Drift Check (5 min)

```
1. Check locally: bash scripts/check-drift.sh
2. Or wait for automated: GitHub Actions runs every 6 hours
3. Review email: Plan output in notification
4. Approve: In GitHub Actions UI
5. Confirm: Get confirmation email
```

### Update Infrastructure (10 min)

```
1. Edit: terraform.tfvars (or code)
2. Plan: terraform plan
3. Review: Check output carefully
4. Apply: terraform apply
5. Verify: terraform output
```

### Emergency Cleanup

```
1. Force unlock: terraform force-unlock <LOCK_ID>
2. Or clean: rm -rf .terraform && terraform init -backend-config=backend-config.hcl
3. Retry: terraform plan && terraform apply
```

## 📖 Documentation Cheat Sheet

**Read based on your need:**

```
Do you know what Terraform is?
├─ Yes → Go to QUICK_REFERENCE.md
└─ No  → Go to README.md

Want to deploy?
├─ Quickly  → Go to QUICKSTART.md
├─ Detailed → Go to README.md
└─ Checklist → Go to DEPLOYMENT_CHECKLIST.md

Need to configure?
├─ Variables → Go to VARIABLES.md
├─ Drift    → Go to DRIFT_DETECTION.md
└─ Commands → Go to QUICK_REFERENCE.md

Got problems?
├─ Terraform error → See README.md Troubleshooting
├─ AWS error       → Check AWS console CloudTrail
└─ Ansible error   → Check user data logs
```

## 🔐 Security Files

These files contain or reference sensitive data:

| File               | Sensitive Info   | Protected How               |
| ------------------ | ---------------- | --------------------------- |
| `terraform.tfvars` | Variables values | `.gitignore` - never commit |
| `.terraform/`      | Temp files       | `.gitignore` - never commit |
| AWS credentials    | In `~/.aws/`     | Never commit - use profiles |
| GitHub Secrets     | GitHub UI        | Encrypted by GitHub         |

## ✅ Validation Checklist

Before using these files:

- [ ] Read [QUICK_REFERENCE.md](./QUICK_REFERENCE.md)
- [ ] Run `terraform validate` to check syntax
- [ ] Run `terraform plan` to preview changes
- [ ] Review [DEPLOYMENT_CHECKLIST.md](./DEPLOYMENT_CHECKLIST.md)
- [ ] Backup existing infrastructure (if any)

## 🆘 Quick Help

**Can't find something?**

1. Check this index file
2. Search README.md
3. Look at QUICK_REFERENCE.md
4. Check Terraform output: `terraform output`
5. View AWS console for resource details

**Which file contains...?**

| What            | File                    |
| --------------- | ----------------------- |
| VPC setup       | main.tf (lines 1-50)    |
| EC2 instances   | main.tf (lines 250-350) |
| ALB config      | main.tf (lines 150-220) |
| Security groups | main.tf (lines 100-150) |
| Variables       | variables.tf            |
| Outputs         | outputs.tf              |
| Ansible config  | playbooks/site.yml      |
| Drift detection | scripts/check-drift.sh  |
| Email sending   | scripts/send_via_ses.sh |

## 📞 Support & Resources

**Getting Help:**

1. **Local issues**: Run `make help` for commands
2. **Configuration**: See VARIABLES.md
3. **Drift detection**: See DRIFT_DETECTION.md
4. **General guide**: See README.md
5. **Quick commands**: See QUICK_REFERENCE.md

**External Resources:**

- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Ansible Documentation](https://docs.ansible.com/)
- [AWS Documentation](https://docs.aws.amazon.com/)

---

## 🎯 Start Here Recommendation

### For New Users

1. ⭐ **QUICK_REFERENCE.md** (5 min) - Get oriented
2. **QUICKSTART.md** (10 min) - Deploy in 5 steps
3. **VARIABLES.md** (15 min) - Customize your setup
4. **README.md** (optional, 30 min) - Deep dive

### For DevOps

1. **README.md** - Full architecture
2. **DRIFT_DETECTION.md** - Setup monitoring
3. **VARIABLES.md** - Customize per environment
4. **Makefile** - Automate workflows

### For Operators

1. **QUICK_REFERENCE.md** - Daily commands
2. **DEPLOYMENT_CHECKLIST.md** - Verify setup
3. **DRIFT_DETECTION.md** - Understand alerts
4. **README.md** Troubleshooting - Fix issues

---

**Last Updated**: 2025-11-28  
**Terraform Version**: >= 1.0  
**Status**: ✅ Complete and ready to use

---

**Pro Tip**: Bookmark [QUICK_REFERENCE.md](./QUICK_REFERENCE.md) and [Makefile](./Makefile) for quick access!
