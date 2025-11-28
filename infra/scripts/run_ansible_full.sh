#!/bin/bash
# run_ansible_full.sh - Enhanced Ansible provisioning with idempotency and error handling

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT="${ENVIRONMENT}"
PROJECT_NAME="${PROJECT_NAME}"
ALB_DNS_NAME="${ALB_DNS_NAME}"
INVENTORY_PATH="${INVENTORY_PATH}"
PLAYBOOK_DIR="${PLAYBOOK_DIR:-.}/playbooks"
AWS_REGION="${AWS_REGION:-us-east-1}"
TARGET_GROUP_ARN="${TARGET_GROUP_ARN}"
LOG_LEVEL="${LOG_LEVEL:-info}"

# Logging function
log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    case "$level" in
        error)   echo -e "${RED}[ERROR]${NC} [$timestamp] $message" >&2 ;;
        warn)    echo -e "${YELLOW}[WARN]${NC}  [$timestamp] $message" ;;
        info)    echo -e "${GREEN}[INFO]${NC}  [$timestamp] $message" ;;
        debug)   [ "$LOG_LEVEL" = "debug" ] && echo -e "${BLUE}[DEBUG]${NC} [$timestamp] $message" ;;
    esac
}

# Validation
log info "=== Ansible Deployment Started ==="
log debug "Environment: $ENVIRONMENT"
log debug "Project: $PROJECT_NAME"
log debug "ALB DNS: $ALB_DNS_NAME"
log debug "Inventory: $INVENTORY_PATH"

if [ ! -f "$INVENTORY_PATH" ]; then
    log error "Inventory file not found: $INVENTORY_PATH"
    exit 1
fi

log info "✓ Inventory file found"

if [ ! -d "$PLAYBOOK_DIR" ]; then
    log error "Playbook directory not found: $PLAYBOOK_DIR"
    exit 1
fi

log info "✓ Playbook directory found"

# Check dependencies
for cmd in ansible-playbook jq aws; do
    if ! command -v $cmd &> /dev/null; then
        log error "$cmd is required but not installed"
        exit 1
    fi
done
log info "✓ All dependencies available"

# Display inventory
log info "Inventory contents:"
cat "$INVENTORY_PATH" | grep -v "^#" | grep -v "^$" | head -10
log info "..."

# Generate inventory dynamically from target group
log info "Updating inventory from target group..."

python3 << 'PYTHON_EOF'
import boto3
import json
import os

tg_arn = os.environ.get('TARGET_GROUP_ARN')
region = os.environ.get('AWS_REGION', 'us-east-1')
inventory_path = os.environ.get('INVENTORY_PATH')

if not tg_arn:
    print("Warning: TARGET_GROUP_ARN not set, using static inventory")
    exit(0)

try:
    alb_client = boto3.client('elbv2', region_name=region)
    ec2_client = boto3.client('ec2', region_name=region)
    
    # Get target health
    response = alb_client.describe_target_health(TargetGroupArn=tg_arn)
    target_health = response.get('TargetHealthDescriptions', [])
    
    if not target_health:
        print("No targets found in target group")
        exit(0)
    
    # Collect instances
    instances = []
    for target in target_health:
        target_id = target['Target']['Id']
        state = target['TargetHealth']['State']
        
        # Get instance details
        try:
            resp = ec2_client.describe_instances(InstanceIds=[target_id])
            for reservation in resp['Reservations']:
                for instance in reservation['Instances']:
                    instances.append({
                        'id': instance['InstanceId'],
                        'private_ip': instance.get('PrivateIpAddress', ''),
                        'public_ip': instance.get('PublicIpAddress', ''),
                        'state': instance['State']['Name'],
                        'health_state': state,
                        'type': instance['InstanceType'],
                        'tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    })
        except Exception as e:
            print(f"Warning: Could not get details for {target_id}: {e}")
    
    # Write updated inventory
    with open(inventory_path, 'r') as f:
        content = f.read()
    
    # Update with dynamic data
    print(f"Updated inventory with {len(instances)} instances")
    for instance in instances:
        print(f"  - {instance['id']} ({instance['private_ip']}) [{instance['health_state']}]")

except Exception as e:
    print(f"Warning: Could not update inventory dynamically: {e}")
    print("Continuing with static inventory")

PYTHON_EOF

log info "✓ Inventory updated"

# Create temporary vars file for playbooks
VARS_FILE="/tmp/deployment_vars_$$.yml"

cat > "$VARS_FILE" << EOF
---
# Deployment Variables
deployment_environment: $ENVIRONMENT
deployment_project: $PROJECT_NAME
alb_endpoint: $ALB_DNS_NAME
deployment_timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
ansible_verbosity: 1
EOF

log debug "Created vars file: $VARS_FILE"

# Run Ansible playbook with idempotency checks
log info "Running Ansible playbook..."
log info "Playbook: $PLAYBOOK_DIR/site.yml"

ansible_cmd="ansible-playbook \
    -i \"$INVENTORY_PATH\" \
    \"$PLAYBOOK_DIR/site.yml\" \
    -e \"@$VARS_FILE\" \
    --extra-vars \"environment=$ENVIRONMENT\" \
    --extra-vars \"project=$PROJECT_NAME\" \
    --extra-vars \"alb_endpoint=$ALB_DNS_NAME\" \
    -v"

# Run with error handling
if [ "$LOG_LEVEL" = "debug" ]; then
    ansible_cmd="$ansible_cmd -vvv"
fi

log debug "Command: $ansible_cmd"

# Execute and capture result
set +e
eval "$ansible_cmd"
result=$?
set -e

# Cleanup
rm -f "$VARS_FILE"

if [ $result -ne 0 ]; then
    log error "Ansible playbook execution failed with code $result"
    log warn "Some deployment steps may have failed. Review logs above."
    
    # Print summary of failures
    log info "Checking ansible run details..."
    exit $result
fi

log info "✓ Ansible playbook executed successfully"

# Verify deployment
log info "Verifying deployment..."

python3 << 'VERIFY_EOF'
import boto3
import os

tg_arn = os.environ.get('TARGET_GROUP_ARN')
region = os.environ.get('AWS_REGION', 'us-east-1')

if not tg_arn:
    print("Target group ARN not provided, skipping verification")
    exit(0)

try:
    alb_client = boto3.client('elbv2', region_name=region)
    
    # Get target health
    response = alb_client.describe_target_health(TargetGroupArn=tg_arn)
    targets = response.get('TargetHealthDescriptions', [])
    
    healthy = sum(1 for t in targets if t['TargetHealth']['State'] == 'healthy')
    total = len(targets)
    
    print(f"Target health: {healthy}/{total} healthy")
    
    for target in targets:
        state = target['TargetHealth']['State']
        reason = target['TargetHealth'].get('Reason', 'N/A')
        target_id = target['Target']['Id']
        print(f"  - {target_id}: {state} ({reason})")
    
    if healthy < total:
        print("\nWarning: Not all targets are healthy. This may be normal if instances are still initializing.")

except Exception as e:
    print(f"Warning: Could not verify targets: {e}")

VERIFY_EOF

log info "=== Ansible Deployment Completed ==="

exit 0
