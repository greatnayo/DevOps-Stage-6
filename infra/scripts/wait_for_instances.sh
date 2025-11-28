#!/bin/bash
# wait_for_instances.sh - Waits for EC2 instances to be ready
# Checks target group health and waits for instances to pass health checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
TARGET_GROUP_ARN="${TARGET_GROUP_ARN}"
AWS_REGION="${AWS_REGION:-us-east-1}"
TIMEOUT="${TIMEOUT:-300}"
CHECK_INTERVAL=10

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
if [ -z "$TARGET_GROUP_ARN" ]; then
    log error "TARGET_GROUP_ARN not set"
    exit 1
fi

log info "=== Waiting for EC2 Instances to be Ready ==="
log info "Target Group: $TARGET_GROUP_ARN"
log info "Region: $AWS_REGION"
log info "Timeout: ${TIMEOUT}s"

# Get initial target count
log info "Fetching target group configuration..."

target_count=$(aws elbv2 describe-target-groups \
    --target-group-arns "$TARGET_GROUP_ARN" \
    --region "$AWS_REGION" \
    --query 'TargetGroups[0].TargetCount' \
    --output text 2>/dev/null || echo "0")

log info "Target count in target group: $target_count"

# Wait for instances to pass health checks
elapsed=0
healthy_count=0
max_attempts=$((TIMEOUT / CHECK_INTERVAL))
attempt=0

while [ $attempt -lt $max_attempts ]; do
    # Get target health status
    health_response=$(aws elbv2 describe-target-health \
        --target-group-arn "$TARGET_GROUP_ARN" \
        --region "$AWS_REGION" \
        --output json)
    
    # Count healthy targets
    healthy_count=$(echo "$health_response" | jq '[.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy")] | length')
    total_count=$(echo "$health_response" | jq '[.TargetHealthDescriptions[]] | length')
    
    log debug "Healthy targets: $healthy_count/$total_count"
    
    # Check if all targets are healthy
    if [ "$healthy_count" -gt 0 ] && [ "$healthy_count" -eq "$total_count" ]; then
        log info "✓ All $healthy_count instances are healthy"
        
        # Get instance details
        instances=$(echo "$health_response" | jq -r '.TargetHealthDescriptions[] | select(.TargetHealth.State == "healthy") | .Target.Id' | head -5)
        log info "Healthy instances:"
        while IFS= read -r instance_id; do
            [ -z "$instance_id" ] && continue
            ip=$(aws ec2 describe-instances \
                --instance-ids "$instance_id" \
                --region "$AWS_REGION" \
                --query 'Reservations[0].Instances[0].PrivateIpAddress' \
                --output text 2>/dev/null || echo "unknown")
            log info "  - $instance_id ($ip)"
        done <<< "$instances"
        
        log info "=== Instances Ready ==="
        exit 0
    fi
    
    # Show status
    attempt=$((attempt + 1))
    elapsed=$((attempt * CHECK_INTERVAL))
    log info "Waiting for instances... ($elapsed/${TIMEOUT}s) [Healthy: $healthy_count/$total_count]"
    
    sleep $CHECK_INTERVAL
done

log error "Timeout waiting for instances to be ready after ${TIMEOUT}s"
log error "Last status: $healthy_count/$total_count healthy"

# Print current health status for debugging
log info "Current target health status:"
aws elbv2 describe-target-health \
    --target-group-arn "$TARGET_GROUP_ARN" \
    --region "$AWS_REGION" \
    --query 'TargetHealthDescriptions[].[Target.Id, TargetHealth.State, TargetHealth.Reason]' \
    --output table || true

exit 1
