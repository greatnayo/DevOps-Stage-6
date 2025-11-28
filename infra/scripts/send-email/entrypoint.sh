#!/bin/bash
# GitHub Action to send email notifications for drift detection

set -e

# Input parameters
EMAIL_TO="${INPUT_EMAIL_TO}"
EMAIL_SUBJECT="${INPUT_EMAIL_SUBJECT}"
DRIFT_DETECTED="${INPUT_DRIFT_DETECTED}"
PLAN_OUTPUT="${INPUT_PLAN_OUTPUT}"
STATUS="${INPUT_STATUS}"
APPLY_OUTPUT="${INPUT_APPLY_OUTPUT}"

if [ -z "$EMAIL_TO" ]; then
    echo "Error: email_to is required"
    exit 1
fi

echo "Sending email notification..."
echo "To: $EMAIL_TO"
echo "Subject: $EMAIL_SUBJECT"

# For local development/testing, you can use AWS SES
# In production, consider using SendGrid, Mailgun, or AWS SES

# Check if using AWS SES
if command -v aws &> /dev/null; then
    /bin/bash "$(dirname "$0")/send_via_ses.sh" \
        "$EMAIL_TO" \
        "$EMAIL_SUBJECT" \
        "$DRIFT_DETECTED" \
        "$PLAN_OUTPUT" \
        "$STATUS" \
        "$APPLY_OUTPUT"
else
    echo "Warning: AWS CLI not found, using fallback notification method"
    # Fallback: Log to GitHub Actions
    echo "EMAIL_NOTIFICATION: $EMAIL_SUBJECT" >> $GITHUB_STEP_SUMMARY
    echo "Recipient: $EMAIL_TO" >> $GITHUB_STEP_SUMMARY
fi

echo "Email notification sent"
