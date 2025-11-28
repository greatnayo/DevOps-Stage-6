#!/bin/bash
# User data script for EC2 instances
# This script runs on instance startup to bootstrap the application

set -e

echo "Starting EC2 instance setup..."

# Log all output
exec > >(tee /var/log/user-data.log)
exec 2>&1

# Update system
yum update -y
yum install -y \
    git \
    curl \
    wget \
    jq \
    python3 \
    python3-pip \
    docker \
    amazon-cloudwatch-agent

# Start Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install Ansible
pip3 install ansible boto3

# Create application directory
mkdir -p /opt/app
cd /opt/app

# Clone repository
git clone https://github.com/greatnayo/DevOps-Stage-6.git . || true

# Create .env file
cat > /opt/app/.env <<EOF
ENVIRONMENT=${environment}
AWS_REGION=us-east-1
EOF

# Download and run Ansible playbook from S3
if [ ! -z "${ansible_playbook_bucket}" ]; then
    echo "Downloading Ansible playbooks from S3..."
    aws s3 sync s3://${ansible_playbook_bucket}/playbooks /opt/app/playbooks --region us-east-1 || true
fi

# Run Ansible locally
if [ -f "/opt/app/playbooks/site.yml" ]; then
    echo "Running Ansible playbook..."
    ansible-playbook /opt/app/playbooks/site.yml \
        -e "environment=${environment}" \
        -c local || true
fi

# Start application services
if [ -f "/opt/app/docker-compose.yml" ]; then
    cd /opt/app
    docker-compose up -d || true
fi

# Health check script
cat > /opt/app/health-check.sh <<'HEALTH'
#!/bin/bash
# Simple health check endpoint

if [ -f /opt/app/.env ]; then
    source /opt/app/.env
fi

# Check if services are running
docker ps | grep -q "healthcheck" && exit 0 || exit 1
HEALTH

chmod +x /opt/app/health-check.sh

# Create systemd service for health checks
cat > /etc/systemd/system/app-health-check.service <<'SERVICE'
[Unit]
Description=Application Health Check
After=docker.service

[Service]
Type=simple
ExecStart=/opt/app/health-check.sh
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload
systemctl enable app-health-check.service
systemctl start app-health-check.service || true

echo "EC2 instance setup completed successfully!"
