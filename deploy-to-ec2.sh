#!/bin/bash

# Direct deployment script for EC2 instance
# This script deploys the microservices application to your existing EC2 instance

set -e

# Configuration
EC2_IP="13.40.112.253"
EC2_USER="ubuntu"  # Default for Ubuntu AMI, change to "ec2-user" for Amazon Linux
KEY_FILE="$HOME/Downloads/myec2keypair.pem"  # SSH key location
DOMAIN="nayo.katonytech.com"

echo "🚀 Starting deployment to EC2 instance: $EC2_IP"

# Check if key file exists
if [ ! -f "$KEY_FILE" ]; then
    echo "❌ SSH key file not found: $KEY_FILE"
    echo "Please update the KEY_FILE variable in this script to point to your SSH key"
    exit 1
fi

# Set correct permissions for SSH key
chmod 600 "$KEY_FILE"

echo "📋 Step 1: Testing SSH connection..."
if ! ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "echo 'SSH connection successful'"; then
    echo "❌ SSH connection failed. Please check:"
    echo "   - SSH key path: $KEY_FILE"
    echo "   - EC2 user: $EC2_USER (try 'ec2-user' for Amazon Linux)"
    echo "   - Security group allows SSH from your IP"
    exit 1
fi

echo "✅ SSH connection successful"

echo "📋 Step 2: Installing dependencies on EC2..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" << 'EOF'
    # Update system
    sudo apt-get update -y

    # Install Docker
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update -y
        sudo apt-get install -y docker-ce
        sudo usermod -aG docker $USER
    fi

    # Install Docker Compose
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Install Git
    if ! command -v git &> /dev/null; then
        echo "Installing Git..."
        sudo apt-get install -y git
    fi

    echo "✅ Dependencies installed"
EOF

echo "📋 Step 3: Cloning repository and deploying application..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" << 'DEPLOY_EOF'
    # Clone or update repository
    if [ -d "DevOps-Stage-6" ]; then
        echo "Updating existing repository..."
        cd DevOps-Stage-6
        git pull origin main
    else
        echo "Cloning repository..."
        git clone https://github.com/$(git config --get remote.origin.url | sed 's/.*github.com[:/]\([^/]*\/[^/]*\)\.git/\1/') DevOps-Stage-6 || \
        git clone https://github.com/your-username/DevOps-Stage-6.git DevOps-Stage-6
        cd DevOps-Stage-6
    fi

    # Copy environment file
    cp .env.example .env 2>/dev/null || cp .env .env.backup

    # Update .env with correct domain
    sed -i "s/DOMAIN=.*/DOMAIN=$DOMAIN/" .env
    sed -i "s/EC2_PUBLIC_IP=.*/EC2_PUBLIC_IP=$EC2_IP/" .env

    echo "✅ Repository ready"
DEPLOY_EOF

echo "📋 Step 4: Building and starting services..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" << 'EOF'
    cd DevOps-Stage-6

    # Stop any existing containers
    sudo docker-compose down 2>/dev/null || true

    # Build and start services
    echo "Building services..."
    sudo docker-compose build

    echo "Starting services..."
    sudo docker-compose up -d

    # Wait for services to start
    echo "Waiting for services to start..."
    sleep 30

    # Check service status
    echo "Service status:"
    sudo docker-compose ps

    echo "✅ Services started"
EOF

echo "📋 Step 5: Health checks..."
echo "Waiting for services to be ready..."
sleep 10

# Test HTTP endpoint
if curl -f -s "http://$EC2_IP" > /dev/null; then
    echo "✅ Frontend is accessible at http://$EC2_IP"
else
    echo "⚠️  Frontend not yet accessible, may need more time to start"
fi

# Test HTTPS endpoint (if domain is configured)
if curl -f -s "https://$DOMAIN" > /dev/null 2>&1; then
    echo "✅ HTTPS is working at https://$DOMAIN"
else
    echo "⚠️  HTTPS not yet configured or domain not pointing to server"
fi

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Access your application:"
echo "   HTTP:  http://$EC2_IP"
echo "   HTTPS: https://$DOMAIN (if DNS is configured)"
echo ""
echo "🔧 Useful commands:"
echo "   Check logs: ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose logs'"
echo "   Restart:    ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose restart'"
echo "   Stop:       ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose down'"
echo ""
echo "📋 Next steps:"
echo "   1. Point your domain $DOMAIN to $EC2_IP"
echo "   2. Update Let's Encrypt to production in .env (LETS_ENCRYPT_CA_SERVER)"
echo "   3. Monitor logs and performance"
EOF