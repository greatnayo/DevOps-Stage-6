#!/bin/bash
# Complete drift detection and notification script
# Usage: ./check-drift.sh [--auto-approve]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
TF_DIR="$PROJECT_ROOT/infra"

ALERT_EMAIL="${ALERT_EMAIL:-}"
AUTO_APPROVE="${1:-}"

echo "=================================================="
echo "Terraform Drift Detection & Management"
echo "=================================================="
echo ""

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    echo "❌ Terraform is not installed"
    exit 1
fi

# Initialize Terraform
echo "1️⃣  Initializing Terraform..."
cd "$TF_DIR"
terraform init -backend-config=backend-config.hcl -upgrade

# Format check
echo ""
echo "2️⃣  Checking Terraform format..."
if terraform fmt -check -recursive 2>/dev/null; then
    echo "✅ Format check passed"
else
    echo "⚠️  Format issues found (auto-fixing)..."
    terraform fmt -recursive
fi

# Validate
echo ""
echo "3️⃣  Validating Terraform configuration..."
if terraform validate; then
    echo "✅ Validation passed"
else
    echo "❌ Validation failed"
    exit 1
fi

# Plan
echo ""
echo "4️⃣  Running Terraform plan..."
if terraform plan -out=tfplan -no-color > plan_output.txt 2>&1; then
    PLAN_STATUS="success"
else
    PLAN_STATUS="failed"
    echo "❌ Terraform plan failed"
    cat plan_output.txt
    exit 1
fi

PLAN_OUTPUT=$(cat plan_output.txt)

# Detect drift
echo ""
echo "5️⃣  Analyzing drift..."
if echo "$PLAN_OUTPUT" | grep -q "No changes"; then
    echo "✅ No drift detected - Infrastructure matches configuration"
    DRIFT_STATUS="no-drift"
else
    echo "⚠️  Drift detected - Infrastructure differs from configuration"
    DRIFT_STATUS="detected"
    
    # Show changes
    echo ""
    echo "Planned Changes:"
    echo "---"
    echo "$PLAN_OUTPUT" | grep "^  \|^-\|^+" | head -20
    echo ""
fi

# Send notification if email is configured
if [ ! -z "$ALERT_EMAIL" ] && [ "$DRIFT_STATUS" = "detected" ]; then
    echo "6️⃣  Sending drift notification to $ALERT_EMAIL..."
    bash "$SCRIPT_DIR/send_via_ses.sh" "$ALERT_EMAIL" "$DRIFT_STATUS" "$PLAN_OUTPUT" || true
fi

# Handle auto-approve or wait for approval
if [ "$DRIFT_STATUS" = "detected" ]; then
    if [ "$AUTO_APPROVE" = "--auto-approve" ]; then
        echo ""
        echo "7️⃣  Auto-approving changes (--auto-approve flag set)..."
        terraform apply -no-color -input=false tfplan
        echo "✅ Terraform apply completed"
    else
        echo ""
        echo "7️⃣  Waiting for approval..."
        echo ""
        echo "Review the changes above carefully."
        read -p "Apply changes? (yes/no): " RESPONSE
        
        if [ "$RESPONSE" = "yes" ]; then
            echo "Applying changes..."
            terraform apply -no-color -input=false tfplan
            echo "✅ Terraform apply completed"
        else
            echo "❌ Changes rejected - No infrastructure modifications made"
            rm -f tfplan
            exit 0
        fi
    fi
else
    echo ""
    echo "✅ All checks passed - No changes required"
fi

# Cleanup
rm -f tfplan plan_output.txt

echo ""
echo "=================================================="
echo "✅ Drift detection completed successfully"
echo "=================================================="
