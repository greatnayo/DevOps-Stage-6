# Drift Detection Setup Guide

This guide explains how to set up automated drift detection with email alerts.

## Quick Start

### 1. Local Drift Detection

```bash
cd infra

# Check for drift
bash scripts/check-drift.sh

# Auto-approve and apply
bash scripts/check-drift.sh --auto-approve
```

### 2. GitHub Actions Setup

#### Step 1: Add GitHub Secrets

Go to repository **Settings** → **Secrets and variables** → **Actions**

Add these secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret key
- `ALERT_EMAIL`: Email address for notifications (e.g., devops@example.com)

#### Step 2: Enable Workflows

1. Go to **Actions** tab
2. Confirm workflow is enabled
3. Workflows will run on schedule (every 6 hours) or manual trigger

#### Step 3: Manual Trigger

```bash
# Using GitHub CLI
gh workflow run terraform-drift-detection.yml

# Or via GitHub UI:
# 1. Click Actions tab
# 2. Select "Terraform Drift Detection & Deployment"
# 3. Click "Run workflow"
```

## Email Configuration

### Using AWS SES

For production email delivery:

```bash
# 1. Verify sender email in AWS SES
aws ses verify-email-identity --email-address your-email@example.com

# 2. Move out of sandbox (if in sandbox mode)
# Contact AWS Support

# 3. Update sender email
export SENDER_EMAIL=your-email@example.com
```

### Environment Variables

```bash
export SENDER_EMAIL=noreply@devops-stage-6.local
export AWS_REGION=us-east-1
```

## Drift Detection Workflow

### Automatic Schedule

By default, drift detection runs:

- **Every 6 hours** (0 _/6 _ \* \*)
- Can be modified in `.github/workflows/terraform-drift-detection.yml`

Change schedule:

```yaml
schedule:
  - cron: "0 0 * * *" # Daily at midnight UTC
```

### Manual Trigger

```bash
gh workflow run terraform-drift-detection.yml
```

### Trigger on Code Push

Drift detection also runs when:

- Any file in `infra/` directory changes
- Workflow file itself changes

## Email Notifications

### Drift Detected Email

You'll receive an email containing:

1. **Drift Summary**

   - Detection timestamp
   - Repository and branch info
   - Drift status (true/false)

2. **Planned Changes**

   - Terraform plan output
   - Specific resources that would change
   - Type of changes (add/modify/delete)

3. **Action Required**
   - Link to GitHub Actions workflow
   - Instructions to approve/reject
   - Environment details

### No Drift Email

When no drift is detected:

- Confirmation email is sent
- Shows infrastructure is up-to-date
- No action required

### Failed Workflow Email

If the workflow fails:

- Error details are shown
- Logs are available in GitHub Actions
- Action required to debug

## Manual Approval

### Step 1: Review Email

Email arrives with subject:

```
🚨 Infrastructure Drift Detected - Manual Approval Required
```

### Step 2: Check GitHub Issue

GitHub automatically creates an issue with:

- Planned changes
- Review instructions
- Action button to approve

### Step 3: Approve Changes

Click the GitHub Actions link or go to:

```
https://github.com/your-org/repo/actions
```

Then:

1. Click the workflow run
2. Review the `terraform-plan` job output
3. Click "Approve and deploy"

### Step 4: Confirm

After approval:

- `terraform apply` runs automatically
- Confirmation email is sent
- Infrastructure is updated

## Troubleshooting

### Email Not Received

1. Check GitHub Actions logs:

   - Go to **Actions** tab
   - Click the failed workflow
   - Check email step

2. Verify AWS SES:

   ```bash
   aws ses list-verified-email-addresses
   ```

3. Check sender email is in sandbox:
   ```bash
   aws ses describe-configuration-set --configuration-set-name default
   ```

### Drift Detected Incorrectly

Sometimes false positives occur:

1. Check what changed:

   ```bash
   cd infra
   terraform plan
   ```

2. If change is expected, approve it
3. If change is not expected, investigate:

   ```bash
   # Show current state
   terraform state show <resource_name>

   # Refresh state
   terraform refresh

   # Plan again
   terraform plan
   ```

### Approval Not Working

1. Check environment protection rule is set

   - Go to **Settings** → **Environments**
   - Verify `terraform-apply` environment has required reviewers

2. Check if you have permission to approve

   - Must be repository admin or in required reviewer team

3. Manually approve in GitHub CLI:
   ```bash
   gh run view <run_id> --json status
   ```

## Advanced Configuration

### Custom Schedule

Edit `.github/workflows/terraform-drift-detection.yml`:

```yaml
on:
  schedule:
    - cron: "0 9 * * MON-FRI" # Weekdays at 9 AM UTC
```

### Custom Email Template

Edit `scripts/send_via_ses.sh`:

```bash
build_email_body() {
    # Customize HTML email
    cat <<EOF
    Your custom email template
    EOF
}
```

### Slack Notifications

Add Slack integration:

```yaml
- name: Notify Slack
  uses: slackapi/slack-github-action@v1
  with:
    payload: |
      {
        "text": "Infrastructure drift detected",
        "blocks": [...]
      }
  env:
    SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

### Multiple Approvers

Set up protection rule:

1. Go to **Settings** → **Branches** → **Branch protection rules**
2. Require approval from multiple people
3. Each must approve before `terraform apply`

## Metrics & Monitoring

### Drift Detection History

View past drift detections:

```bash
# List all workflow runs
gh run list --workflow=terraform-drift-detection.yml

# Show specific run
gh run view <run_id>

# Download logs
gh run download <run_id>
```

### Track Changes Over Time

```bash
# View terraform state versions
aws s3api list-object-versions \
  --bucket devops-stage-6-terraform-state \
  --prefix infra/terraform.tfstate
```

### Performance Metrics

Drift detection typically takes:

- **Plan**: 2-5 minutes
- **Analysis**: < 1 minute
- **Email**: < 1 minute
- **Total**: ~5-10 minutes

## Best Practices

### 1. Review All Drifts

Never approve blindly:

- Always review the planned changes
- Understand why drift occurred
- Reject suspicious changes

### 2. Document Drifts

Keep a log of drifts:

```bash
# Log drift to file
echo "$(date): Drift detected - $(gh run view <run_id> --json status)" >> drift-log.txt
```

### 3. Alert Team

For production, notify team before approving:

- Post in Slack
- Create incident ticket
- Wait for team approval

### 4. Automate Approvals (With Caution)

Only for non-production:

```yaml
# Remove request-approval job for auto-approval
# ⚠️ NOT recommended for prod!
```

### 5. Review Email Templates

Keep email templates up-to-date with:

- Current environment info
- Escalation contacts
- Runbook links

## Security Considerations

### 1. Credential Rotation

Rotate AWS credentials regularly:

```bash
# Generate new access keys
aws iam create-access-key --user-name terraform-user

# Update GitHub Secrets
# Delete old access key
```

### 2. Email Security

- Use encryption for sensitive diffs
- Restrict email recipient
- Use verified email addresses only

### 3. Approval Access

- Limit approvers to trusted team members
- Use GitHub Enterprise for SAML/SSO
- Enable audit logs

### 4. S3 State Bucket

```bash
# Enable versioning (done by setup script)
aws s3api put-bucket-versioning \
  --bucket devops-stage-6-terraform-state \
  --versioning-configuration Status=Enabled

# Block public access
aws s3api put-public-access-block \
  --bucket devops-stage-6-terraform-state \
  --public-access-block-configuration \
  "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

## FAQ

### Q: Can I schedule drift detection at different times?

**A:** Yes, edit the cron expression in the workflow file.

### Q: What if I don't want to receive emails?

**A:** Remove the `send-drift-notification` job from the workflow.

### Q: Can I auto-approve for dev but require approval for prod?

**A:** Yes, use separate workflows or branch rules.

### Q: What's the difference between drift and planned changes?

**A:**

- **Drift**: Changes made outside of Terraform
- **Planned Changes**: Changes you made in Terraform code

Both trigger the same approval workflow for safety.

### Q: How do I skip the approval for urgent changes?

**A:** Use the `--auto-approve` flag locally, or remove the approval job temporarily (production requires caution).

---

**Need help?** See the main [README.md](./README.md) or check logs with:

```bash
cd infra
TF_LOG=DEBUG terraform plan
```
