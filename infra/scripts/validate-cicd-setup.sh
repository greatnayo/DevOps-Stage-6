#!/bin/bash
# infra/scripts/validate-cicd-setup.sh
# Validates that all CI/CD components are properly configured

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

echo "=================================================="
echo "CI/CD Setup Validation"
echo "=================================================="
echo ""

VALIDATION_ERRORS=0

# Check Ansible roles
echo "1. Checking Ansible roles..."
ROLES=(
    "dependencies"
    "deploy"
)

for role in "${ROLES[@]}"; do
    ROLE_DIR="$PROJECT_ROOT/infra/playbooks/roles/$role"
    
    if [ -d "$ROLE_DIR" ]; then
        echo "  ✓ Role '$role' exists"
        
        # Check for required files
        if [ -f "$ROLE_DIR/tasks/main.yml" ]; then
            echo "    ✓ tasks/main.yml"
        else
            echo "    ✗ tasks/main.yml MISSING"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        
        if [ -f "$ROLE_DIR/handlers/main.yml" ]; then
            echo "    ✓ handlers/main.yml"
        else
            echo "    ✗ handlers/main.yml MISSING"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        
        if [ -f "$ROLE_DIR/defaults/main.yml" ]; then
            echo "    ✓ defaults/main.yml"
        else
            echo "    ✗ defaults/main.yml MISSING"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    else
        echo "  ✗ Role '$role' NOT FOUND"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
done

echo ""
echo "2. Checking GitHub Workflows..."
WORKFLOWS=(
    "infra-terraform-ansible.yml"
    "app-deploy-services.yml"
    "scheduled-drift-detection.yml"
    "send-email.yml"
)

for workflow in "${WORKFLOWS[@]}"; do
    WORKFLOW_FILE="$PROJECT_ROOT/.github/workflows/$workflow"
    if [ -f "$WORKFLOW_FILE" ]; then
        echo "  ✓ $workflow"
        
        # Check for basic structure
        if grep -q "name:" "$WORKFLOW_FILE"; then
            echo "    ✓ Contains name field"
        else
            echo "    ✗ Missing name field"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
        
        if grep -q "on:" "$WORKFLOW_FILE"; then
            echo "    ✓ Contains trigger configuration"
        else
            echo "    ✗ Missing trigger configuration"
            VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
        fi
    else
        echo "  ✗ $workflow NOT FOUND"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
done

echo ""
echo "3. Checking Ansible playbook..."
PLAYBOOK="$PROJECT_ROOT/infra/playbooks/site.yml"
if [ -f "$PLAYBOOK" ]; then
    echo "  ✓ site.yml exists"
    
    if grep -q "roles:" "$PLAYBOOK"; then
        echo "    ✓ Uses roles"
    else
        echo "    ✗ Doesn't use roles"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
else
    echo "  ✗ site.yml NOT FOUND"
    VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
fi

echo ""
echo "4. Checking Traefik templates..."
TEMPLATES=(
    "traefik-config.yml.j2"
    "traefik-routing.yml.j2"
    "docker-compose.env.j2"
)

for template in "${TEMPLATES[@]}"; do
    TEMPLATE_FILE="$PROJECT_ROOT/infra/playbooks/roles/deploy/templates/$template"
    if [ -f "$TEMPLATE_FILE" ]; then
        echo "  ✓ $template"
    else
        echo "  ✗ $template NOT FOUND"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
done

echo ""
echo "5. Checking documentation..."
DOCS=(
    "CICD_GUIDE.md"
    "CICD_QUICK_SETUP.md"
)

for doc in "${DOCS[@]}"; do
    DOC_FILE="$PROJECT_ROOT/$doc"
    if [ -f "$DOC_FILE" ]; then
        echo "  ✓ $doc"
        LINES=$(wc -l < "$DOC_FILE")
        echo "    ($LINES lines)"
    else
        echo "  ✗ $doc NOT FOUND"
        VALIDATION_ERRORS=$((VALIDATION_ERRORS + 1))
    fi
done

echo ""
echo "6. Checking required scripts..."
SCRIPTS=(
    "check-drift.sh"
    "generate_inventory.sh"
    "run_ansible.sh"
)

for script in "${SCRIPTS[@]}"; do
    SCRIPT_FILE="$PROJECT_ROOT/infra/scripts/$script"
    if [ -f "$SCRIPT_FILE" ]; then
        echo "  ✓ $script"
    else
        echo "  ⚠ $script (pre-existing, may not be created)"
    fi
done

echo ""
echo "=================================================="
echo "Validation Summary"
echo "=================================================="
echo ""

if [ $VALIDATION_ERRORS -eq 0 ]; then
    echo "✅ All CI/CD components are properly configured!"
    echo ""
    echo "Next steps:"
    echo "1. Configure GitHub repository secrets:"
    echo "   - AWS_ROLE_TO_ASSUME"
    echo "   - ALERT_EMAIL"
    echo "   - SES_EMAIL_FROM"
    echo ""
    echo "2. Test workflows:"
    echo "   - Push to main branch to trigger infrastructure workflow"
    echo "   - Or use workflow_dispatch for manual trigger"
    echo ""
    echo "3. Monitor first run:"
    echo "   - Go to GitHub Actions tab"
    echo "   - Review logs and outputs"
    echo ""
    exit 0
else
    echo "❌ Found $VALIDATION_ERRORS validation error(s)"
    echo ""
    echo "Please review the errors above and correct them."
    echo ""
    exit 1
fi
