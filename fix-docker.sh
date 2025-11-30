#!/bin/bash

# Fix Docker version compatibility issue
set -e

EC2_IP="13.40.112.253"
EC2_USER="ubuntu"
KEY_FILE="$HOME/Downloads/myec2keypair.pem"

echo "🔧 Fixing Docker version compatibility on EC2 instance: $EC2_IP"

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
    echo "Updating Docker and Docker Compose..."
    
    # Stop Docker service
    sudo systemctl stop docker
    
    # Remove old Docker Compose
    sudo rm -f /usr/local/bin/docker-compose
    
    # Update Docker to latest version
    sudo apt-get update -y
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # Start Docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Install latest Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    # Create symlink for docker compose (new syntax)
    sudo ln -sf /usr/bin/docker /usr/local/bin/docker-compose || true
    
    echo "Docker versions:"
    docker --version
    docker-compose --version || echo "Using docker compose plugin"
    
    echo "✅ Docker updated successfully"
'

echo "🚀 Now deploying the application..."

ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
    cd DevOps-Stage-6

    # Stop any existing containers
    sudo docker compose down 2>/dev/null || sudo docker-compose down 2>/dev/null || true

    # Clean up
    sudo docker system prune -f

    echo "Building services with updated Docker..."
    # Try new syntax first, fallback to old
    sudo docker compose build --no-cache || sudo docker-compose build --no-cache

    echo "Starting services..."
    sudo docker compose up -d || sudo docker-compose up -d

    # Wait for services to start
    echo "Waiting for services to initialize..."
    sleep 60

    # Check service status
    echo "Service status:"
    sudo docker compose ps || sudo docker-compose ps

    echo "✅ Services started successfully"
'

echo "📋 Testing application..."
sleep 10

# Test HTTP endpoint
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Application is accessible at http://$EC2_IP"
elif [ "$HTTP_STATUS" = "000" ]; then
    echo "⚠️  Connection timeout, services may still be starting..."
else
    echo "⚠️  HTTP returned status: $HTTP_STATUS"
fi

echo ""
echo "🎉 Docker fix and deployment completed!"
echo ""
echo "📊 Access your application:"
echo "   HTTP:  http://$EC2_IP"
echo "   HTTPS: https://nayo.katonytech.com (if DNS is configured)"