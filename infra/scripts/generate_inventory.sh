#!/bin/bash
# Dynamic inventory script for Ansible
# This script generates Ansible inventory from EC2 instances in the target group

set -e

REGION="${AWS_REGION:-us-east-1}"
TARGET_GROUP_ARN="${TARGET_GROUP_ARN}"
OUTPUT_FILE="${OUTPUT_FILE:-.}/inventory/hosts.ini}"

if [ -z "$TARGET_GROUP_ARN" ]; then
    echo "ERROR: TARGET_GROUP_ARN not set"
    exit 1
fi

echo "Generating dynamic inventory from EC2 instances..."

python3 << 'EOF'
import boto3
import json
import os
from datetime import datetime

def get_instances_from_target_group(tg_arn, region):
    """Fetch instances registered in the target group"""
    alb_client = boto3.client('elbv2', region_name=region)
    ec2_client = boto3.client('ec2', region_name=region)
    
    try:
        # Get target health
        response = alb_client.describe_target_health(TargetGroupArn=tg_arn)
        target_health = response.get('TargetHealthDescriptions', [])
        
        instance_ids = [target['Target']['Id'] for target in target_health if target['Target']['Type'] == 'instance']
        
        if not instance_ids:
            print("No instances found in target group")
            return []
        
        # Get instance details
        instances_response = ec2_client.describe_instances(InstanceIds=instance_ids)
        
        instances = []
        for reservation in instances_response['Reservations']:
            for instance in reservation['Instances']:
                instances.append({
                    'id': instance['InstanceId'],
                    'private_ip': instance.get('PrivateIpAddress', ''),
                    'public_ip': instance.get('PublicIpAddress', ''),
                    'state': instance['State']['Name'],
                    'type': instance['InstanceType'],
                    'availability_zone': instance['Placement']['AvailabilityZone'],
                    'tags': {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                })
        
        return instances
    except Exception as e:
        print(f"Error fetching instances: {e}")
        return []

def generate_inventory(instances):
    """Generate Ansible inventory format"""
    inventory = "[all_instances]\n"
    
    for instance in instances:
        if instance['state'] == 'running':
            # Use private IP for internal communication
            ip = instance['private_ip'] or instance['public_ip']
            name = instance['tags'].get('Name', instance['id'])
            inventory += f"{name} ansible_host={ip} instance_id={instance['id']}\n"
    
    inventory += "\n[all_instances:vars]\n"
    inventory += "ansible_python_interpreter=/usr/bin/python3\n"
    inventory += "ansible_user=ec2-user\n"
    inventory += "ansible_ssh_private_key_file=~/.ssh/id_rsa\n"
    inventory += "ansible_ssh_common_args='-o StrictHostKeyChecking=no'\n"
    
    return inventory

# Main
tg_arn = os.environ.get('TARGET_GROUP_ARN')
region = os.environ.get('AWS_REGION', 'us-east-1')
output_file = os.environ.get('OUTPUT_FILE', './inventory/hosts.ini')

instances = get_instances_from_target_group(tg_arn, region)
inventory = generate_inventory(instances)

# Create directory if it doesn't exist
os.makedirs(os.path.dirname(output_file), exist_ok=True)

# Write inventory
with open(output_file, 'w') as f:
    f.write(inventory)

print(f"Inventory generated: {output_file}")
print(f"Instances found: {len(instances)}")
for instance in instances:
    print(f"  - {instance['tags'].get('Name', instance['id'])} ({instance['private_ip']})")
EOF
