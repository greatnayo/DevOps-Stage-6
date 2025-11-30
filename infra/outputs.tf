output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "private_subnet_id" {
  description = "Private subnet ID"
  value       = aws_subnet.private.id
}

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.main.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.main.arn
}

output "target_group_arn" {
  description = "ARN of the target group"
  value       = aws_lb_target_group.main.arn
}

output "asg_name" {
  description = "Name of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.name
}

output "asg_arn" {
  description = "ARN of the Auto Scaling Group"
  value       = aws_autoscaling_group.app.arn
}

output "app_security_group_id" {
  description = "Security group ID for application servers"
  value       = aws_security_group.app.id
}

output "alb_security_group_id" {
  description = "Security group ID for load balancer"
  value       = aws_security_group.alb.id
}

output "iam_role_arn" {
  description = "ARN of the IAM role for EC2 instances"
  value       = aws_iam_role.app.arn
}

output "inventory_file_path" {
  description = "Path to generated Ansible inventory file"
  value       = local_file.ansible_inventory.filename
}

output "nat_gateway_ip" {
  description = "Elastic IP of the NAT Gateway"
  value       = aws_eip.nat.public_ip
}

output "terraform_state_bucket" {
  description = "S3 bucket for Terraform state"
  value       = var.terraform_state_bucket
  sensitive   = true
}

output "drift_detection_enabled" {
  description = "Whether drift detection is enabled"
  value       = true
}

output "infrastructure_summary" {
  description = "Summary of provisioned infrastructure"
  value = {
    environment     = var.environment
    project         = var.project_name
    region          = var.aws_region
    asg_name        = aws_autoscaling_group.app.name
    alb_endpoint    = aws_lb.main.dns_name
    min_capacity    = var.asg_min_size
    max_capacity    = var.asg_max_size
    desired_capacity = var.asg_desired_capacity
    state_backend   = "s3"
  }
}
