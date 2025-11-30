output "vpc_id" {
  description = "VPC ID"
  value       = var.vpc_id
}

output "instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.app.id
}

output "instance_private_ip" {
  description = "Private IP address of the EC2 instance"
  value       = aws_instance.app.private_ip
}

output "instance_public_ip" {
  description = "Elastic IP address of the EC2 instance"
  value       = aws_eip.app.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_eip.app.public_dns
}

output "security_group_id" {
  description = "Security group ID for application server"
  value       = aws_security_group.app.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instance"
  value       = aws_iam_role.app.arn
}

output "cloudwatch_log_group" {
  description = "CloudWatch log group for application"
  value       = aws_cloudwatch_log_group.app.name
}

output "application_url" {
  description = "URL to access the application"
  value       = "http://${aws_eip.app.public_ip}"
}

output "traefik_dashboard_url" {
  description = "URL to access Traefik dashboard"
  value       = "http://${aws_eip.app.public_ip}:8080/dashboard/"
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i <your-key.pem> ec2-user@${aws_eip.app.public_ip}"
}

output "infrastructure_summary" {
  description = "Summary of provisioned infrastructure"
  value = {
    environment        = var.environment
    project            = var.project_name
    region             = var.aws_region
    vpc_id             = var.vpc_id
    instance_type      = var.instance_type
    instance_public_ip = aws_eip.app.public_ip
    state_backend      = "local"
  }
}
