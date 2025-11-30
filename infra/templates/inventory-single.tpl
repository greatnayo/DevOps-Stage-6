[all]
app_server ansible_host=${instance_ip} ansible_user=ec2-user

[all_instances]
app_server ansible_host=${instance_ip} ansible_user=ec2-user

[all:vars]
ansible_connection=local
environment=${environment}
project_name=${project_name}
aws_region=${aws_region}
instance_public_ip=${instance_public_ip}
instance_id=${instance_id}
app_directory=/opt/app
