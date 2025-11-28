#!/bin/bash
# Email notification script for local/manual drift detection
# Usage: ./notify-drift.sh <email> <status> [plan_output]

EMAIL="${1}"
STATUS="${2:-unknown}"
PLAN_OUTPUT="${3:-}"

if [ -z "$EMAIL" ]; then
    echo "Usage: $0 <email> <status> [plan_output]"
    exit 1
fi

# Use sendmail or mail command if available
send_notification() {
    local email=$1
    local status=$2
    local plan=$3
    
    # Create email body
    local subject="Infrastructure Drift Detected: $status"
    local body="Infrastructure Drift Notification\n\n"
    body+="Status: $status\n"
    body+="Timestamp: $(date)\n"
    body+="Hostname: $(hostname)\n\n"
    
    if [ ! -z "$plan" ]; then
        body+="Planned Changes:\n"
        body+="$plan\n\n"
    fi
    
    body+="Please review and take appropriate action.\n"
    
    # Try different email methods
    if command -v mail &> /dev/null; then
        echo -e "$body" | mail -s "$subject" "$email"
        echo "✅ Notification sent via mail command"
    elif command -v sendmail &> /dev/null; then
        (echo "Subject: $subject"; echo ""; echo -e "$body") | sendmail "$email"
        echo "✅ Notification sent via sendmail"
    else
        echo "⚠️  No mail command available"
        echo "Would send to: $email"
        echo "Subject: $subject"
        echo "---"
        echo -e "$body"
    fi
}

send_notification "$EMAIL" "$STATUS" "$PLAN_OUTPUT"
