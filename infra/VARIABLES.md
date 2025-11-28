# Terraform Variables Reference

## Usage

Create a `terraform.tfvars` file to customize your deployment:

```hcl
aws_region              = "us-east-1"
project_name            = "devops-stage-6"
environment             = "dev"
instance_type           = "t3.medium"
asg_desired_capacity    = 2
ssh_allowed_cidr        = ["203.0.113.0/32"]  # Your IP
```

## Variables

### `aws_region`

- **Type**: `string`
- **Default**: `us-east-1`
- **Description**: AWS region for infrastructure
- **Example**: `us-east-1`, `eu-west-1`, `ap-southeast-1`

### `project_name`

- **Type**: `string`
- **Default**: `devops-stage-6`
- **Description**: Project name for resource naming (affects all resource names)

### `environment`

- **Type**: `string`
- **Default**: `dev`
- **Allowed Values**: `dev`, `staging`, `prod`
- **Description**: Environment name for resource tagging and configuration

### `vpc_cidr`

- **Type**: `string`
- **Default**: `10.0.0.0/16`
- **Description**: CIDR block for VPC

### `public_subnet_cidr`

- **Type**: `string`
- **Default**: `10.0.1.0/24`
- **Description**: CIDR block for public subnet (contains NAT Gateway & ALB)

### `private_subnet_cidr`

- **Type**: `string`
- **Default**: `10.0.2.0/24`
- **Description**: CIDR block for private subnet (contains EC2 instances)

### `ami_id`

- **Type**: `string`
- **Default**: `ami-0c55b159cbfafe1f0` (Amazon Linux 2)
- **Description**: AMI ID for EC2 instances
- **Finding AMIs**:
  ```bash
  # Amazon Linux 2
  aws ec2 describe-images --owners amazon --filters "Name=name,Values=amzn2-ami-hvm-*" --query 'Images[0].ImageId'
  ```

### `instance_type`

- **Type**: `string`
- **Default**: `t3.medium`
- **Description**: EC2 instance type
- **Allowed**: t2._, t3._, t4._, m5._, m6._, m7._
- **Options**:
  - `t3.micro`: Small, free tier (if eligible)
  - `t3.small`: Development
  - `t3.medium`: Production minimum
  - `t3.large`: High traffic

### `asg_min_size`

- **Type**: `number`
- **Default**: `1`
- **Description**: Minimum number of instances in Auto Scaling Group
- **Constraint**: Must be > 0

### `asg_max_size`

- **Type**: `number`
- **Default**: `3`
- **Description**: Maximum number of instances in Auto Scaling Group
- **Constraint**: Must be >= `asg_min_size`

### `asg_desired_capacity`

- **Type**: `number`
- **Default**: `2`
- **Description**: Desired number of instances in Auto Scaling Group
- **Constraint**: Must be between `asg_min_size` and `asg_max_size`

### `ssh_allowed_cidr`

- **Type**: `list(string)`
- **Default**: `["0.0.0.0/0"]`
- **Description**: CIDR blocks allowed for SSH access
- **⚠️ Security**: Restrict in production!
- **Examples**:
  ```hcl
  ssh_allowed_cidr = ["203.0.113.0/32"]  # Single IP
  ssh_allowed_cidr = ["203.0.113.0/24"]  # CIDR range
  ssh_allowed_cidr = ["203.0.113.0/32", "198.51.100.0/24"]  # Multiple
  ```

### `ansible_playbook_bucket`

- **Type**: `string`
- **Default**: `devops-stage-6-ansible-playbooks`
- **Description**: S3 bucket containing Ansible playbooks for instance configuration

### `terraform_state_bucket`

- **Type**: `string`
- **Default**: `devops-stage-6-terraform-state`
- **Description**: S3 bucket for storing Terraform state

### `tags`

- **Type**: `map(string)`
- **Default**:
  ```hcl
  {
    Terraform   = "true"
    ManagedBy   = "terraform"
    CreatedDate = "2025-11-28"
  }
  ```
- **Description**: Common tags applied to all resources

## Environment-Specific Configuration

### Development Environment

```hcl
# terraform-dev.tfvars
environment          = "dev"
instance_type        = "t3.small"
asg_desired_capacity = 1
asg_max_size         = 2
ssh_allowed_cidr     = ["0.0.0.0/0"]  # Permissive for development
```

Deploy:

```bash
terraform apply -var-file=terraform-dev.tfvars
```

### Staging Environment

```hcl
# terraform-staging.tfvars
environment          = "staging"
instance_type        = "t3.medium"
asg_desired_capacity = 2
asg_max_size         = 5
ssh_allowed_cidr     = ["10.0.0.0/8"]  # Internal only
```

### Production Environment

```hcl
# terraform-prod.tfvars
environment          = "prod"
instance_type        = "m5.large"
asg_min_size         = 2
asg_desired_capacity = 3
asg_max_size         = 10
ssh_allowed_cidr     = ["203.0.113.0/32"]  # Specific IP only
```

## Using Variables

### Via Command Line

```bash
terraform apply -var='environment=prod' -var='instance_type=m5.large'
```

### Via File

```bash
terraform apply -var-file=terraform-prod.tfvars
```

### Via Environment Variables

```bash
export TF_VAR_environment=prod
export TF_VAR_instance_type=m5.large
terraform apply
```

### Interactive (Not Recommended)

```bash
terraform apply
# Terraform will prompt for each variable
```

## Outputs

After `terraform apply`, access infrastructure details:

```bash
# All outputs
terraform output

# Specific output
terraform output alb_dns_name

# JSON format
terraform output -json
```

See `outputs.tf` for all available outputs.

## Validation

Terraform validates variables automatically:

```bash
terraform validate
```

Custom validation examples:

```hcl
# Instance type validation
validation {
  condition     = can(regex("^t[2-4]\\.", var.instance_type))
  error_message = "Instance type must be t2, t3, or t4"
}

# Environment validation
validation {
  condition     = contains(["dev", "staging", "prod"], var.environment)
  error_message = "Environment must be: dev, staging, or prod"
}

# ASG capacity validation
validation {
  condition     = var.asg_desired_capacity >= var.asg_min_size && var.asg_desired_capacity <= var.asg_max_size
  error_message = "Desired capacity must be between min and max"
}
```

## Sensitive Variables

For secrets, use `sensitive = true`:

```bash
# Environment variable
export TF_VAR_db_password="your_secret_password"

# Terraform won't show in logs
terraform plan
# Shows: db_password = <sensitive>
```

## Common Patterns

### Dev/Test with Minimal Cost

```bash
terraform apply \
  -var='environment=dev' \
  -var='instance_type=t3.micro' \
  -var='asg_desired_capacity=1' \
  -var='asg_max_size=1'
```

### Scale Up for Load Testing

```bash
terraform apply -var='asg_desired_capacity=5'
```

### Quick Cleanup

```bash
terraform destroy -var-file=terraform-dev.tfvars
```

---

**For more information**, see the main [README.md](./README.md)
