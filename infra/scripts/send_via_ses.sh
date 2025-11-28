#!/bin/bash
# Send email via AWS SES (Simple Email Service)

EMAIL_TO="$1"
EMAIL_SUBJECT="$2"
DRIFT_DETECTED="$3"
PLAN_OUTPUT="$4"
STATUS="$5"
APPLY_OUTPUT="$6"

AWS_REGION="${AWS_REGION:-us-east-1}"
SENDER_EMAIL="${SENDER_EMAIL:-noreply@devops-stage-6.local}"

# Build HTML email body
build_email_body() {
    local status=$1
    local drift=$2
    local plan=$3
    
    cat <<EOF
<!DOCTYPE html>
<html>
<head>
    <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background-color: #0066cc; color: white; padding: 20px; border-radius: 5px; }
        .status { font-weight: bold; font-size: 18px; }
        .status.success { color: #28a745; }
        .status.warning { color: #ffc107; }
        .status.error { color: #dc3545; }
        .section { margin: 20px 0; padding: 15px; background-color: #f8f9fa; border-left: 4px solid #0066cc; }
        .code { background-color: #f4f4f4; padding: 10px; border-radius: 3px; overflow-x: auto; }
        pre { margin: 0; }
        .footer { margin-top: 20px; padding-top: 20px; border-top: 1px solid #ccc; font-size: 12px; color: #666; }
        .action-button { display: inline-block; padding: 10px 20px; margin: 10px 0; background-color: #0066cc; color: white; text-decoration: none; border-radius: 3px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>Infrastructure Drift Detection Report</h1>
            <p class="status warning">⚠️ Status: $status</p>
        </div>

        <div class="section">
            <h2>Drift Detection Summary</h2>
            <p><strong>Drift Detected:</strong> $drift</p>
            <p><strong>Timestamp:</strong> $(date -u +'%Y-%m-%dT%H:%M:%SZ')</p>
            <p><strong>Repository:</strong> $GITHUB_REPOSITORY</p>
            <p><strong>Branch:</strong> $GITHUB_REF</p>
        </div>

        $(if [ "$drift" = "true" ]; then echo "
        <div class=\"section\">
            <h2>Planned Changes</h2>
            <div class=\"code\">
                <pre>$plan</pre>
            </div>
            <p><strong>Action Required:</strong> Please review the changes and approve or reject the Terraform apply.</p>
            <a href=\"$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\" class=\"action-button\">Review in GitHub</a>
        </div>
        "; fi)

        <div class=\"section\">
            <h2>Environment Details</h2>
            <ul>
                <li><strong>Project:</strong> DevOps-Stage-6</li>
                <li><strong>Terraform Version:</strong> 1.5.0</li>
                <li><strong>AWS Region:</strong> $AWS_REGION</li>
                <li><strong>Workflow Run:</strong> <a href=\"$GITHUB_SERVER_URL/$GITHUB_REPOSITORY/actions/runs/$GITHUB_RUN_ID\">View Details</a></li>
            </ul>
        </div>

        <div class=\"section\">
            <h2>Next Steps</h2>
            <ol>
                <li>Review the infrastructure changes above</li>
                <li>Visit the GitHub Actions workflow to approve or reject changes</li>
                <li>Changes will be automatically applied upon approval</li>
                <li>You will receive a confirmation email once applied</li>
            </ol>
        </div>

        <div class=\"footer\">
            <p>This is an automated message from the DevOps-Stage-6 CI/CD pipeline.</p>
            <p>Do not reply to this email. Instead, use the GitHub Actions workflow to manage approvals.</p>
            <p>&copy; 2025 DevOps-Stage-6. All rights reserved.</p>
        </div>
    </div>
</body>
</html>
EOF
}

# Send via AWS SES
send_email_ses() {
    local to=$1
    local subject=$2
    local body=$3
    
    # Check if AWS credentials are available
    if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
        echo "Warning: AWS credentials not available for SES"
        return 1
    fi
    
    aws ses send-email \
        --to "$to" \
        --from "$SENDER_EMAIL" \
        --subject "$subject" \
        --html "$body" \
        --region "$AWS_REGION" 2>/dev/null || return 1
    
    return 0
}

# Main execution
EMAIL_BODY=$(build_email_body "$STATUS" "$DRIFT_DETECTED" "$PLAN_OUTPUT")

if send_email_ses "$EMAIL_TO" "$EMAIL_SUBJECT" "$EMAIL_BODY"; then
    echo "✅ Email sent successfully to $EMAIL_TO"
else
    echo "⚠️  Email delivery failed - falling back to GitHub Actions notification"
    echo "Email would have been sent to: $EMAIL_TO"
    echo "Subject: $EMAIL_SUBJECT"
    echo "---"
    echo "$EMAIL_BODY" | head -20
fi
