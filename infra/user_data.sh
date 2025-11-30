#!/bin/bash
# User data script for EC2 instance
# This script runs on instance startup to bootstrap the application

# Don't exit on error - log them instead
set +e

echo "Starting EC2 instance setup..."

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

# Update system
yum update -y --skip-broken || true
yum install -y --allowerasing \
    git \
    curl \
    wget \
    jq \
    python3 \
    python3-pip \
    docker \
    amazon-cloudwatch-agent || yum install -y git wget jq python3 python3-pip docker || true

echo "Installed system dependencies"

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

echo "Docker started and enabled"

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

echo "Docker Compose installed"

# Install Ansible and dependencies
echo "Installing Ansible..."
pip3 install ansible boto3 botocore 2>/dev/null || pip install ansible boto3 botocore 2>/dev/null || echo "Warning: Ansible install had issues, will continue"

echo "Ansible installed"

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Clone repository
echo "Cloning repository..."
git clone https://github.com/greatnayo/DevOps-Stage-6.git . || git pull

echo "Repository cloned/updated"

# Create .env file with default values
cat > /opt/app/.env <<EOF
ENVIRONMENT=${environment}
AWS_REGION=eu-west-2
PROJECT_NAME=${project_name}
DOMAIN=localhost
ACME_EMAIL=greatnayo@gmail.com
TRAEFIK_DASHBOARD_ENABLED=true
TRAEFIK_API_INSECURE=false
TRAEFIK_LOG_LEVEL=INFO
JWT_SECRET=myfancysecret
AUTH_API_PORT=8081
USERS_API_PORT=8083
TODOS_API_PORT=8082
ZIPKIN_URL=
EOF

echo "Environment file created"

# Run Ansible locally to configure the system
if [ -f "/opt/app/infra/playbooks/site.yml" ]; then
    echo "Running Ansible playbook..."
    cd /opt/app
    ansible-playbook infra/playbooks/site.yml \
        -i /opt/app/infra/inventory/hosts.ini \
        -e "environment=${environment}" \
        -e "ansible_connection=local" \
        --tags "dependencies,deploy" || true
    echo "Ansible playbook completed"
fi

# Start application services
if [ -f "/opt/app/docker-compose.yml" ]; then
    echo "Starting Docker Compose services..."
    cd /opt/app
    # Add current user to docker group and use sudo to run docker-compose
    docker-compose up -d 2>&1 | tee -a /var/log/docker-compose-startup.log
    COMPOSE_EXIT=$?
    echo "Docker Compose exit code: $COMPOSE_EXIT"
    echo "Docker Compose services started"
    
    # Wait for services to be ready
    echo "Waiting for services to stabilize..."
    sleep 10
    
    # Log running containers
    echo "Currently running containers:"
    docker ps 2>&1 | tee -a /var/log/docker-compose-startup.log
    
    # Check if traefik is running
    if docker ps | grep -q traefik; then
        echo "✓ Traefik container is running"
    else
        echo "✗ Traefik container is NOT running"
        echo "All containers:"
        docker ps -a
        echo "Docker logs:"
        docker logs -f 2>&1 | head -100
    fi
else
    echo "Docker Compose file not found at /opt/app/docker-compose.yml"
    ls -la /opt/app/ 2>&1 | head -20
fi

# Create systemd service for health checks
cat > /etc/systemd/system/app-health-check.service <<'SERVICE'
[Unit]
Description=Application Health Check
After=docker.service

[Service]
Type=simple
ExecStart=/bin/bash -c 'while true; do if docker ps | grep -q traefik; then exit 0; else exit 1; fi; done'
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable app-health-check.service || true

echo "EC2 instance setup completed successfully"
echo "Application services should be running on this instance"
