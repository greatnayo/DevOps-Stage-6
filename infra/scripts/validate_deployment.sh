#!/bin/bash
# validate_deployment.sh - Validates the deployment and performs health checks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
ALB_DNS_NAME="${ALB_DNS_NAME}"
HEALTH_CHECK_URL="${HEALTH_CHECK_URL:-/health}"
MAX_RETRIES="${MAX_RETRIES:-30}"
RETRY_INTERVAL="${RETRY_INTERVAL:-10}"
ENVIRONMENT="${ENVIRONMENT}"
PROJECT_NAME="${PROJECT_NAME}"
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

log info "=== Deployment Validation Started ==="
log info "ALB DNS: $ALB_DNS_NAME"
log info "Health Check URL: http://$ALB_DNS_NAME$HEALTH_CHECK_URL"

# Validation
if [ -z "$ALB_DNS_NAME" ]; then
    log error "ALB_DNS_NAME not set"
    exit 1
fi

# Check if ALB is accessible
log info "Checking ALB accessibility..."

for attempt in $(seq 1 $MAX_RETRIES); do
    log debug "Attempt $attempt/$MAX_RETRIES"
    
    # Try to connect to ALB
    if curl -sf "http://$ALB_DNS_NAME$HEALTH_CHECK_URL" -m 5 > /dev/null 2>&1; then
        log info "✓ ALB is responding to health checks"
        log info "✓ Health check passed at: http://$ALB_DNS_NAME$HEALTH_CHECK_URL"
        
        # Get more details
        http_code=$(curl -s -o /dev/null -w "%{http_code}" "http://$ALB_DNS_NAME$HEALTH_CHECK_URL" -m 5)
        log info "✓ HTTP Response Code: $http_code"
        
        # Verify multiple endpoints
        log info "Verifying application endpoints..."
        
        # Check common endpoints
        for endpoint in "/" "/api/health" "/health" "/status"; do
            if curl -sf "http://$ALB_DNS_NAME$endpoint" -m 3 > /dev/null 2>&1; then
                log info "  ✓ $endpoint is accessible"
            else
                log debug "  - $endpoint may not be available (optional)"
            fi
        done
        
        log info "=== Deployment Validation Successful ==="
        exit 0
    fi
    
    if [ $attempt -lt $MAX_RETRIES ]; then
        elapsed=$((attempt * RETRY_INTERVAL))
        remaining=$(((MAX_RETRIES - attempt) * RETRY_INTERVAL))
        log info "Waiting for application to be ready... ($elapsed elapsed, $remaining remaining)"
        sleep $RETRY_INTERVAL
    fi
done

log error "Application did not become ready after $((MAX_RETRIES * RETRY_INTERVAL)) seconds"
log error "The ALB may not have any healthy instances or the application may not be responding"

# Print diagnostic information
log info "Attempting diagnostic information..."

# Check if ALB DNS is resolvable
if ping -c 1 "$ALB_DNS_NAME" > /dev/null 2>&1; then
    alb_ip=$(dig +short "$ALB_DNS_NAME" | head -1)
    log info "ALB IP Address: $alb_ip"
else
    log warn "Could not resolve ALB DNS name: $ALB_DNS_NAME"
fi

# List available ports
log info "Attempting to connect to ALB on different ports:"
for port in 80 443 8080; do
    timeout 2 bash -c "echo > /dev/tcp/$ALB_DNS_NAME/$port" 2>/dev/null && \
        log info "  ✓ Port $port is open" || \
        log debug "  - Port $port is not accessible"
done

exit 1
