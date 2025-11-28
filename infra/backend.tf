# Backend Configuration for Remote State Storage
# This file sets up S3 + DynamoDB for Terraform state management with locking

terraform {
  backend "s3" {
    # Bucket name for storing Terraform state
    # You can customize this by editing terraform/backend-config.hcl
    bucket         = "devops-stage-6-terraform-state"
    
    # Key path within the bucket
    key            = "infra/terraform.tfstate"
    
    # AWS region
    region         = "us-east-1"
    
    # Enable server-side encryption
    encrypt        = true
    
    # DynamoDB table for state locking (prevents concurrent modifications)
    dynamodb_table = "terraform-locks"
  }
}

# This configuration ensures:
# 1. State is stored securely in S3
# 2. State is encrypted at rest
# 3. Concurrent modifications are prevented via DynamoDB locks
# 4. State is consistent across team members

# SETUP INSTRUCTIONS:
# 1. Create S3 bucket:
#    aws s3 mb s3://devops-stage-6-terraform-state --region us-east-1
#
# 2. Enable versioning:
#    aws s3api put-bucket-versioning \
#      --bucket devops-stage-6-terraform-state \
#      --versioning-configuration Status=Enabled
#
# 3. Enable encryption:
#    aws s3api put-bucket-encryption \
#      --bucket devops-stage-6-terraform-state \
#      --server-side-encryption-configuration '{
#        "Rules": [{
#          "ApplyServerSideEncryptionByDefault": {
#            "SSEAlgorithm": "AES256"
#          }
#        }]
#      }'
#
# 4. Block public access:
#    aws s3api put-public-access-block \
#      --bucket devops-stage-6-terraform-state \
#      --public-access-block-configuration \
#        "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
#
# 5. Create DynamoDB table for locking:
#    aws dynamodb create-table \
#      --table-name terraform-locks \
#      --attribute-definitions AttributeName=LockID,AttributeType=S \
#      --key-schema AttributeName=LockID,KeyType=HASH \
#      --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
#      --region us-east-1
