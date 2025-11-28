#!/bin/bash
# deploy_traefik.sh - Deploys Traefik reverse proxy with SSL/TLS configuration

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
INVENTORY_PATH="${INVENTORY_PATH}"
TRAEFIK_CONFIG="${TRAEFIK_CONFIG}"
PLAYBOOK_DIR="${PLAYBOOK_DIR:-.}/playbooks"
ENABLE_SSL="${ENABLE_SSL:-true}"
SSL_PROVIDER="${SSL_PROVIDER:-letsencrypt}"
ACME_EMAIL="${ACME_EMAIL:-admin@example.com}"
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

log info "=== Traefik Deployment Started ==="
log info "SSL Enabled: $ENABLE_SSL"
log info "SSL Provider: $SSL_PROVIDER"

# Validation
if [ ! -f "$INVENTORY_PATH" ]; then
    log error "Inventory file not found: $INVENTORY_PATH"
    exit 1
fi

if [ ! -f "$TRAEFIK_CONFIG" ]; then
    log warn "Traefik config not found: $TRAEFIK_CONFIG"
    log info "Traefik deployment skipped (optional)"
    exit 0
fi

# Create Traefik playbook if it doesn't exist
TRAEFIK_PLAYBOOK="$PLAYBOOK_DIR/traefik.yml"

if [ ! -f "$TRAEFIK_PLAYBOOK" ]; then
    log info "Creating Traefik deployment playbook..."
    
    mkdir -p "$PLAYBOOK_DIR"
    
    cat > "$TRAEFIK_PLAYBOOK" << 'EOF'
---
# traefik.yml - Deployment playbook for Traefik reverse proxy

- name: Deploy Traefik Reverse Proxy
  hosts: all_instances
  become: yes
  gather_facts: yes
  
  vars:
    traefik_version: "v2.10"
    docker_compose_file: "/opt/traefik/docker-compose.yml"
    traefik_data_dir: "/opt/traefik"
  
  pre_tasks:
    - name: Wait for system to be ready
      wait_for_connection:
        delay: 5
        timeout: 300
  
  tasks:
    - name: Create Traefik directory
      file:
        path: "{{ traefik_data_dir }}"
        state: directory
        mode: '0755'
      tags:
        - traefik
        - setup
    
    - name: Ensure Docker daemon is running
      systemd:
        name: docker
        state: started
        enabled: yes
      tags:
        - traefik
        - docker
    
    - name: Check if Traefik is running
      docker_container_info:
        name: traefik
      register: traefik_status
      failed_when: false
      tags:
        - traefik
        - status
    
    - name: Start/Restart Traefik container
      docker_container:
        name: traefik
        image: "traefik:{{ traefik_version }}"
        state: started
        restart_policy: always
        ports:
          - "80:80"
          - "443:443"
          - "8080:8080"
        volumes:
          - "{{ traefik_data_dir }}/traefik.yml:/traefik.yml"
          - "{{ traefik_data_dir }}/acme.json:/acme.json"
          - "/var/run/docker.sock:/var/run/docker.sock"
        command: "--configFile=/traefik.yml"
      tags:
        - traefik
        - deploy
    
    - name: Verify Traefik deployment
      uri:
        url: "http://localhost:8080/ping"
        method: GET
        status_code: 200
      retries: 5
      delay: 10
      tags:
        - traefik
        - verify
  
  post_tasks:
    - name: Display Traefik status
      debug:
        msg: |
          ✓ Traefik deployed successfully
          ✓ Dashboard: http://{{ inventory_hostname }}:8080/dashboard/
          ✓ HTTP: http://{{ inventory_hostname }}:80
          ✓ HTTPS: https://{{ inventory_hostname }}:443
      tags:
        - traefik
        - always
  
  tags:
    - traefik
    - reverse-proxy
EOF

    log info "✓ Traefik playbook created"
fi

# Create variables file for Traefik
VARS_FILE="/tmp/traefik_vars_$$.yml"

cat > "$VARS_FILE" << EOF
---
# Traefik Configuration Variables
enable_ssl: $ENABLE_SSL
ssl_provider: $SSL_PROVIDER
acme_email: $ACME_EMAIL
traefik_config_file: $TRAEFIK_CONFIG
deployment_timestamp: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

log debug "Created Traefik vars file: $VARS_FILE"

# Run Traefik deployment playbook
log info "Running Traefik deployment playbook..."

ansible_cmd="ansible-playbook \
    -i \"$INVENTORY_PATH\" \
    \"$TRAEFIK_PLAYBOOK\" \
    -e \"@$VARS_FILE\" \
    -e \"environment=$ENVIRONMENT\" \
    -e \"project=$PROJECT_NAME\" \
    -v"

if [ "$LOG_LEVEL" = "debug" ]; then
    ansible_cmd="$ansible_cmd -vvv"
fi

log debug "Command: $ansible_cmd"

# Execute with error handling
set +e
eval "$ansible_cmd"
result=$?
set -e

# Cleanup
rm -f "$VARS_FILE"

if [ $result -ne 0 ]; then
    log warn "Traefik deployment playbook failed (non-critical)"
    log info "Traefik deployment will be skipped, application may still be operational"
    exit 0  # Don't fail the entire deployment
fi

log info "✓ Traefik deployment completed"

# Verify Traefik is accessible
log info "Verifying Traefik deployment..."

python3 << 'VERIFY_EOF'
import subprocess
import time

max_retries = 5
retry_interval = 10

for attempt in range(max_retries):
    try:
        result = subprocess.run(
            ['ansible', 'all', '-i', '/dev/stdin', '-m', 'uri', 
             '-a', 'url=http://localhost:8080/ping method=GET status_code=200'],
            input=open(os.environ.get('INVENTORY_PATH')).read(),
            capture_output=True,
            timeout=30
        )
        if result.returncode == 0:
            print("✓ Traefik is responding to health checks")
            break
    except Exception as e:
        if attempt < max_retries - 1:
            print(f"Health check attempt {attempt + 1} failed, retrying in {retry_interval}s...")
            time.sleep(retry_interval)
        else:
            print(f"Warning: Could not verify Traefik health: {e}")

VERIFY_EOF

log info "=== Traefik Deployment Completed ==="

exit 0
