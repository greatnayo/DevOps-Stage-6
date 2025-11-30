#!/bin/bash

# Deploy from GitHub repository to EC2 instance
set -e

EC2_IP="13.40.112.253"
EC2_USER="ubuntu"
KEY_FILE="$HOME/Downloads/myec2keypair.pem"
DOMAIN="nayo.katonytech.com"
REPO_URL="https://github.com/greatnayo/DevOps-Stage-6.git"

echo "🚀 Starting deployment to EC2 instance: $EC2_IP"
echo "📦 Repository: $REPO_URL"

# Test SSH connection
echo "📋 Testing SSH connection..."
ssh -i "$KEY_FILE" -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "echo 'SSH connection successful'"

echo "📋 Installing dependencies on EC2..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
    # Update system
    sudo apt-get update -y

    # Install required packages
    sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common git

    # Install Docker if not present
    if ! command -v docker &> /dev/null; then
        echo "Installing Docker..."
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

    echo "✅ Dependencies installed"
'

echo "📋 Cloning repository from GitHub..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "
    # Remove existing directory if it exists
    rm -rf DevOps-Stage-6

    # Clone the repository
    echo 'Cloning from: $REPO_URL'
    git clone $REPO_URL
    
    if [ -d 'DevOps-Stage-6' ]; then
        echo '✅ Repository cloned successfully'
    else
        echo '❌ Failed to clone repository'
        exit 1
    fi
"

echo "📋 Configuring environment..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "
    cd DevOps-Stage-6
    
    # Show current .env content
    echo 'Current .env configuration:'
    head -10 .env
    
    # Update .env file with correct values
    sed -i 's|DOMAIN=.*|DOMAIN=$DOMAIN|' .env
    sed -i 's|EC2_PUBLIC_IP=.*|EC2_PUBLIC_IP=$EC2_IP|' .env
    
    echo ''
    echo 'Updated .env configuration:'
    head -10 .env
    
    echo '✅ Environment configured'
"

echo "📋 Building and starting services..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
    cd DevOps-Stage-6

    # Stop any existing containers
    sudo docker-compose down 2>/dev/null || true

    # Clean up any existing containers/images
    sudo docker system prune -f 2>/dev/null || true

    echo "Building services (this may take several minutes)..."
    sudo docker-compose build --no-cache

    echo "Starting services..."
    sudo docker-compose up -d

    # Wait for services to start
    echo "Waiting for services to initialize..."
    sleep 60

    # Check service status
    echo "Service status:"
    sudo docker-compose ps

    echo "✅ Services deployment completed"
'

echo "📋 Running health checks..."
sleep 20

# Test HTTP endpoint
echo "Testing HTTP endpoint..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://$EC2_IP" || echo "000")

if [ "$HTTP_STATUS" = "200" ]; then
    echo "✅ Frontend is accessible at http://$EC2_IP"
elif [ "$HTTP_STATUS" = "000" ]; then
    echo "⚠️  Connection failed, checking if services are still starting..."
else
    echo "⚠️  HTTP returned status: $HTTP_STATUS, checking service logs..."
fi

# Get service status and logs
echo "📋 Service diagnostics..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
    cd DevOps-Stage-6
    
    echo "=== Container Status ==="
    sudo docker-compose ps
    
    echo ""
    echo "=== Recent Logs (last 20 lines) ==="
    sudo docker-compose logs --tail=20
    
    echo ""
    echo "=== Port Status ==="
    sudo netstat -tlnp | grep -E ":80|:443|:8080" || echo "No services listening on web ports yet"
'

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Access your application:"
echo "   HTTP:  http://$EC2_IP"
echo "   HTTPS: https://$DOMAIN (if DNS is configured)"
echo "   Traefik Dashboard: http://$EC2_IP:8080 (if enabled)"
echo ""
echo "🔧 Useful commands:"
echo "   Check logs: ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose logs'"
echo "   Follow logs: ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose logs -f'"
echo "   Restart:    ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose restart'"
echo "   Stop:       ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose down'"
echo "   Rebuild:    ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd DevOps-Stage-6 && sudo docker-compose build --no-cache && sudo docker-compose up -d'"
echo ""
echo "📋 Next steps:"
echo "   1. Point your domain $DOMAIN to $EC2_IP in your DNS settings"
echo "   2. Wait 5-10 minutes for all services to fully start"
echo "   3. Update Let's Encrypt to production in .env (change LETS_ENCRYPT_CA_SERVER)"
echo "   4. Monitor logs for any issues"
echo ""
echo "🔍 If services aren't accessible immediately:"
echo "   - Services may still be starting (wait 5-10 minutes)"
echo "   - Check logs with the commands above"
echo "   - Ensure security group allows HTTP/HTTPS traffic"