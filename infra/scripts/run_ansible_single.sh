#!/bin/bash
# Script to run Ansible playbook for single EC2 instance deployment

set -e

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="${SCRIPT_DIR%/*}"
PLAYBOOK_DIR="${PROJECT_DIR}/playbooks"
INVENTORY_PATH="${INVENTORY_PATH:-${PROJECT_DIR}/inventory/hosts.ini}"
ENVIRONMENT="${ENVIRONMENT:-dev}"
PROJECT_NAME="${PROJECT_NAME:-devops-stage-6}"

echo "========================================="
echo "Ansible Deployment Script - Single EC2"
echo "========================================="
echo "Project: $PROJECT_NAME"
echo "Environment: $ENVIRONMENT"
echo "Inventory: $INVENTORY_PATH"
echo "========================================="

# Check if inventory file exists
if [ ! -f "$INVENTORY_PATH" ]; then
    echo "ERROR: Inventory file not found at $INVENTORY_PATH"
    exit 1
fi

# Check if playbook exists
if [ ! -f "$PLAYBOOK_DIR/site.yml" ]; then
    echo "ERROR: Playbook not found at $PLAYBOOK_DIR/site.yml"
    exit 1
fi

# Verify Ansible is installed
if ! command -v ansible-playbook &> /dev/null; then
    echo "WARNING: Ansible is not installed. Attempting to install..."
    pip3 install ansible boto3 botocore || echo "Failed to install Ansible"
fi

# Wait a bit for instance to be ready
echo "Waiting for instance to be ready..."
sleep 10

# Configure passwordless sudo for current user if needed
echo "Setting up passwordless sudo for Ansible..."

# Get current username
CURRENT_USER=$(whoami)

# Check if current user already has passwordless sudo
if ! sudo -n true 2>/dev/null; then
    echo "Setting up passwordless sudo for $CURRENT_USER..."
    # Add current user to sudoers with NOPASSWD for ansible-playbook
    if [ "$CURRENT_USER" != "root" ]; then
        echo "Please enter your sudo password to configure passwordless sudo:"
        (echo ""; cat << 'SUDOERS' | sudo tee /etc/sudoers.d/$CURRENT_USER-ansible > /dev/null
# Allow $CURRENT_USER to run ansible without password
$CURRENT_USER ALL=(ALL) NOPASSWD: /usr/bin/ansible-playbook, /usr/bin/python*, /bin/mkdir, /bin/chmod, /bin/chown, /usr/bin/pip*, /usr/local/bin/*
SUDOERS
        ) || echo "Failed to configure sudoers, will attempt to continue..."
        sudo chmod 440 /etc/sudoers.d/$CURRENT_USER-ansible 2>/dev/null || true
    fi
else
    echo "User already has passwordless sudo"
fi

# Give it a moment to take effect
sleep 2

# Run Ansible playbook
echo "Running Ansible playbook..."
cd "$PROJECT_DIR"

ansible-playbook \
    -i "$INVENTORY_PATH" \
    -e "environment=$ENVIRONMENT" \
    -e "project_name=$PROJECT_NAME" \
    -e "ansible_connection=local" \
    -e "app_directory=/opt/app" \
    "$PLAYBOOK_DIR/site.yml" \
    --tags "dependencies,deploy" \
    -v

echo "========================================="
echo "Ansible deployment completed successfully"
echo "========================================="

