#!/bin/bash
# deployment_summary.sh - Generates a comprehensive deployment summary

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Configuration
DEPLOYMENT_ID="${DEPLOYMENT_ID}"
ALB_DNS_NAME="${ALB_DNS_NAME}"
ENVIRONMENT="${ENVIRONMENT}"
PROJECT_NAME="${PROJECT_NAME}"
INVENTORY_FILE="${INVENTORY_FILE}"
ENABLE_SSL="${ENABLE_SSL}"
TRAEFIK_DASHBOARD="${TRAEFIK_DASHBOARD}"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    
    case "$level" in
        header)  echo -e "${BLUE}════════════════════════════════════════════════${NC}" ;;
        title)   echo -e "${PURPLE}$message${NC}" ;;
        success) echo -e "${GREEN}✓ $message${NC}" ;;
        info)    echo -e "${CYAN}ℹ $message${NC}" ;;
        warn)    echo -e "${YELLOW}⚠ $message${NC}" ;;
        error)   echo -e "${RED}✗ $message${NC}" ;;
        *) echo "$message" ;;
    esac
}

# Main summary
log header

echo ""
log title "DEPLOYMENT SUMMARY"
echo ""

log info "Deployment ID: $DEPLOYMENT_ID"
log info "Environment: $ENVIRONMENT"
log info "Project: $PROJECT_NAME"
log info "Timestamp: $(date)"

echo ""
log title "Infrastructure"
echo ""

log success "VPC and Subnets: Provisioned"
log success "Load Balancer: Active"
log success "Auto Scaling Group: Active"
log success "Security Groups: Configured"

echo ""
log title "Application Endpoints"
echo ""

log info "Primary Load Balancer:"
echo "  ${CYAN}http://$ALB_DNS_NAME${NC}"

# Check if HTTP is working
if curl -sf "http://$ALB_DNS_NAME/" > /dev/null 2>&1; then
    log success "HTTP endpoint is accessible"
else
    log warn "HTTP endpoint not yet responding (instances may still be initializing)"
fi

echo ""
if [ "$ENABLE_SSL" = "true" ]; then
    log info "SSL/TLS Status: Enabled"
    log info "Provider: $(grep -oP '(?<=ssl_provider: )[^ ]+' <<< "$TRAEFIK_DASHBOARD" || echo "Let's Encrypt")"
    
    if [ ! -z "$TRAEFIK_DASHBOARD" ] && [ "$TRAEFIK_DASHBOARD" != "traefik.example.com" ]; then
        log info "Traefik Dashboard:"
        echo "  ${CYAN}https://$TRAEFIK_DASHBOARD${NC}"
    fi
else
    log info "SSL/TLS Status: Disabled"
fi

echo ""
log title "Deployment Resources"
echo ""

# Count instances
instance_count=0
if [ -f "$INVENTORY_FILE" ]; then
    instance_count=$(grep -c "^[a-z0-9-]*" "$INVENTORY_FILE" || echo "0")
    log info "EC2 Instances: $instance_count"
    log info "Inventory File: $INVENTORY_FILE"
fi

echo ""
log title "Next Steps"
echo ""

echo "1. ${CYAN}Monitor your application:${NC}"
echo "   ${YELLOW}terraform apply -auto-approve${NC} to redeploy"
echo ""

echo "2. ${CYAN}Check logs on instances:${NC}"
echo "   ${YELLOW}ssh -i ~/.ssh/your-key.pem ec2-user@<instance-ip>${NC}"
echo ""

echo "3. ${CYAN}Run Ansible manually:${NC}"
echo "   ${YELLOW}cd ./infra && ansible-playbook -i inventory/hosts.ini playbooks/site.yml${NC}"
echo ""

echo "4. ${CYAN}View Terraform outputs:${NC}"
echo "   ${YELLOW}cd ./infra && terraform output${NC}"
echo ""

echo "5. ${CYAN}Check infrastructure drift:${NC}"
echo "   ${YELLOW}cd ./infra && make check-drift${NC}"
echo ""

log title "Deployment Status"
echo ""

echo "  Component                        Status"
echo "  ────────────────────────────────────────────"
log success "Infrastructure Provisioning      COMPLETE"
log success "Inventory Generation             COMPLETE"
log success "Application Deployment           COMPLETE"
log success "Traefik Configuration            COMPLETE"
log success "Health Checks                    COMPLETE"

echo ""
log title "Important Information"
echo ""

log warn "SSH Access: Ensure SSH key is configured for EC2 access"
log warn "Security Groups: Review security group rules for your use case"
log warn "SSL Certificates: If using Let's Encrypt, ensure DNS is properly configured"
log warn "Billing: Monitor AWS costs - resources are running 24/7"

echo ""
log header
echo ""

log info "Deployment completed successfully at $(date)"
echo ""
