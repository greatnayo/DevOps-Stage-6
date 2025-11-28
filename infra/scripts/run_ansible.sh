#!/bin/bash
# Script to run Ansible playbooks after Terraform provisioning

set -e

echo "=== Ansible Provisioning Started ==="
echo "Environment: ${ENVIRONMENT}"
echo "Project: ${PROJECT_NAME}"
echo "ALB DNS: ${ALB_DNS_NAME}"
echo "Inventory Path: ${INVENTORY_PATH}"

# Wait for instances to be ready
echo "Waiting for instances to be ready (60 seconds)..."
sleep 60

# Update inventory with live EC2 instances
echo "Updating dynamic inventory..."
python3 -c "
import boto3
import json

ec2 = boto3.client('ec2', region_name='us-east-1')

# Get instances from target group
alb = boto3.client('elbv2', region_name='us-east-1')
targets = alb.describe_target_health(TargetGroupArn='${TG_ARN}')

instances = []
for target in targets.get('TargetHealthDescriptions', []):
    if 'TargetId' in target:
        instance_id = target['TargetId']
        # Get instance details
        response = ec2.describe_instances(InstanceIds=[instance_id])
        for reservation in response['Reservations']:
            for instance in reservation['Instances']:
                instances.append({
                    'id': instance['InstanceId'],
                    'ip': instance.get('PrivateIpAddress', ''),
                    'state': instance['State']['Name']
                })

print(json.dumps(instances, indent=2))
" || echo "Warning: Could not fetch dynamic inventory"

# Check if instances are ready
if [ ! -f "${INVENTORY_PATH}" ]; then
    echo "ERROR: Inventory file not found at ${INVENTORY_PATH}"
    exit 1
fi

echo "Running Ansible playbook..."
# Run Ansible playbook - adjust based on your playbook location
ansible-playbook -i "${INVENTORY_PATH}" ./playbooks/site.yml \
    -e "environment=${ENVIRONMENT}" \
    -e "project=${PROJECT_NAME}" \
    -e "alb_endpoint=${ALB_DNS_NAME}" \
    -v || echo "Warning: Ansible playbook execution had issues"

echo "=== Ansible Provisioning Completed ==="
