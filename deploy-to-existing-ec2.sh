#!/bin/bash

# Deploy to existing EC2 instance (13.40.112.253)
set -e

EC2_IP="13.40.112.253"
EC2_USER="ubuntu"
KEY_FILE="$HOME/Downloads/myec2keypair.pem"
DOMAIN="nayo.katonytech.com"
ALB_DNS="app20251129111227337000000002-627145169.eu-west-2.elb.amazonaws.com"

echo "🚀 Deploying application to existing EC2 instance: $EC2_IP"
echo "📊 ALB DNS: $ALB_DNS"

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

    echo "✅ Dependencies installed"
'

echo "📋 Copying application files..."
# Copy the entire project to EC2
scp -i "$KEY_FILE" -o StrictHostKeyChecking=no -r . "$EC2_USER@$EC2_IP:~/microservices-app/"

echo "📋 Configuring and starting services..."
ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" "
    cd ~/microservices-app
    
    # Update .env file with correct values
    sed -i 's/DOMAIN=.*/DOMAIN=$DOMAIN/' .env
    sed -i 's/EC2_PUBLIC_IP=.*/EC2_PUBLIC_IP=$EC2_IP/' .env
    
    # Stop any existing containers
    sudo docker-compose down 2>/dev/null || true
    
    # Build and start services
    echo 'Building services (this may take a few minutes)...'
    sudo docker-compose build
    
    echo 'Starting services...'
    sudo docker-compose up -d
    
    # Wait for services to start
    echo 'Waiting for services to start...'
    sleep 45
    
    # Check service status
    echo 'Service status:'
    sudo docker-compose ps
    
    echo '✅ Services started'
"

echo "📋 Running health checks..."
sleep 15

# Test HTTP endpoint on EC2 instance
echo "Testing HTTP endpoint on EC2 instance..."
if curl -f -s "http://$EC2_IP" > /dev/null; then
    echo "✅ Frontend is accessible at http://$EC2_IP"
else
    echo "⚠️  Frontend not yet accessible on EC2, checking logs..."
    ssh -i "$KEY_FILE" -o StrictHostKeyChecking=no "$EC2_USER@$EC2_IP" '
        cd ~/microservices-app
        echo "Container status:"
        sudo docker-compose ps
        echo ""
        echo "Recent logs:"
        sudo docker-compose logs --tail=10
    '
fi

# Test ALB endpoint
echo "Testing ALB endpoint..."
if curl -f -s "http://$ALB_DNS" > /dev/null; then
    echo "✅ ALB is accessible at http://$ALB_DNS"
else
    echo "⚠️  ALB not yet accessible (this is expected since app is on different instance)"
fi

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📊 Access your application:"
echo "   Direct EC2:  http://$EC2_IP"
echo "   Domain:      https://$DOMAIN (if DNS is configured)"
echo "   ALB:         http://$ALB_DNS (will work once instances are registered)"
echo ""
echo "🔧 Useful commands:"
echo "   Check logs: ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd ~/microservices-app && sudo docker-compose logs'"
echo "   Restart:    ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd ~/microservices-app && sudo docker-compose restart'"
echo "   Stop:       ssh -i $KEY_FILE $EC2_USER@$EC2_IP 'cd ~/microservices-app && sudo docker-compose down'"
echo ""
echo "📋 Next steps:"
echo "   1. Point your domain $DOMAIN to $EC2_IP in your DNS settings"
echo "   2. The ALB ($ALB_DNS) is ready but points to different instances"
echo "   3. You can use either the direct EC2 access or configure the ALB to point to this instance"