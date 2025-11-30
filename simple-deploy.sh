#!/bin/bash

# Simple deployment script for EC2 instance
set -e

EC2_IP="13.40.112.253"
EC2_USER="ubuntu"
KEY_FILE="$HOME/Downloads/myec2keypair.pem"
DOMAIN="nayo.katonytech.com"

echo "🚀 Starting deployment to EC2 instance: $EC2_IP"

# Test SSH connection
echo "📋 Testing SSH connection..."
ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "echo 'SSH connection successful'"

echo "📋 Installing dependencies..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
    # Update system
    sudo apt-get update -y

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
        sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
        sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
        sudo apt-get update -y
        sudo apt-get install -y docker-ce
        sudo usermod -aG docker $USER
        sudo systemctl start docker
        sudo systemctl enable docker
    fi

    # Install Docker Compose if not present
    if ! command -v docker-compose &> /dev/null; then
        echo "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.21.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
    fi

    # Install Git if not present
    if ! command -v git &> /dev/null; then
        echo "Installing Git..."
        sudo apt-get install -y git
    fi

    echo "✅ Dependencies installed"
'

echo "📋 Cloning repository..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "
    # Remove existing directory if it exists
    rm -rf DevOps-Stage-6

    # Clone the repository
    git clone https://github.com/nayosx/DevOps-Stage-6.git
    cd DevOps-Stage-6

    # Update .env file
    sed -i 's/DOMAIN=.*/DOMAIN=$DOMAIN/' .env
    sed -i 's/EC2_PUBLIC_IP=.*/EC2_PUBLIC_IP=$EC2_IP/' .env

    echo '✅ Repository cloned and configured'
"

echo "📋 Building and starting services..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
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
'

echo "📋 Running health checks..."
sleep 10

# Test HTTP endpoint
if curl -f -s "http://$EC2_IP" > /dev/null; then
    echo "✅ Frontend is accessible at http://$EC2_IP"
else
    echo "⚠️  Frontend not yet accessible, checking logs..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" 'cd DevOps-Stage-6 && sudo docker-compose logs --tail=20'
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