[local]
localhost ansible_connection=local

[all_instances]
# This section will be populated dynamically by Terraform

[${project_name}_${environment}]
# Auto-scaled instances discovered via EC2 API

[all_instances:vars]
ansible_python_interpreter=/usr/bin/python3
ansible_user=ec2-user
ansible_ssh_private_key_file=~/.ssh/id_rsa
ansible_ssh_common_args='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'

[deployers:children]
all_instances

# Load Balancer Configuration
[loadbalancers]
# ALB DNS: ${alb_dns_name}

[infrastructure:vars]
environment=${environment}
project_name=${project_name}
alb_endpoint=${alb_dns_name}
asg_name=${asg_name}
target_group_arn=${target_group_arn}

# Service Configuration
[todos_api]
# Todos API instances

[users_api]
# Users API instances

[auth_api]
# Auth API instances

[frontend]
# Frontend instances
