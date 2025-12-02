[todo_server]
localhost ansible_host=${server_ip} ansible_user=${server_user} ansible_ssh_private_key_file=${private_key_path}

[todo_server:vars]
ansible_python_interpreter=/usr/bin/python3