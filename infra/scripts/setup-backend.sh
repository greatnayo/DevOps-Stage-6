#!/bin/bash
# Terraform Backend Setup Script
# Creates S3 bucket and DynamoDB table for remote state management

set -e

AWS_REGION="${AWS_REGION:-us-east-1}"
BUCKET_NAME="devops-stage-6-terraform-state"
DYNAMODB_TABLE="terraform-locks"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "================================"
echo "Terraform Backend Setup"
echo "================================"
echo "AWS Region: $AWS_REGION"
echo "S3 Bucket: $BUCKET_NAME"
echo "DynamoDB Table: $DYNAMODB_TABLE"
echo ""

# Create S3 bucket
echo "1. Creating S3 bucket for Terraform state..."
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    aws s3 mb "s3://$BUCKET_NAME" --region "$AWS_REGION"
    echo "✅ S3 bucket created"
else
    echo "✅ S3 bucket already exists"
fi

# Enable versioning
echo "2. Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --region "$AWS_REGION"
echo "✅ Versioning enabled"

# Enable encryption
echo "3. Enabling encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [{
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }]
    }' \
    --region "$AWS_REGION"
echo "✅ Encryption enabled"

# Block public access
echo "4. Blocking public access..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$AWS_REGION"
echo "✅ Public access blocked"

# Create DynamoDB table
echo "5. Creating DynamoDB table for state locking..."
if aws dynamodb describe-table --table-name "$DYNAMODB_TABLE" --region "$AWS_REGION" 2>/dev/null | grep -q "TableName"; then
    echo "✅ DynamoDB table already exists"
else
    aws dynamodb create-table \
        --table-name "$DYNAMODB_TABLE" \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
        --region "$AWS_REGION"
    echo "✅ DynamoDB table created"
fi

# Add tags to S3 bucket
echo "6. Adding tags..."
aws s3api put-bucket-tagging \
    --bucket "$BUCKET_NAME" \
    --tagging 'TagSet=[
        {Key=Project,Value=DevOps-Stage-6},
        {Key=Purpose,Value=TerraformState},
        {Key=ManagedBy,Value=Terraform}
    ]' \
    --region "$AWS_REGION"
echo "✅ Tags added"

echo ""
echo "================================"
echo "✅ Backend setup completed!"
echo "================================"
echo ""
echo "Backend Configuration:"
echo "  Bucket: $BUCKET_NAME"
echo "  Region: $AWS_REGION"
echo "  DynamoDB Table: $DYNAMODB_TABLE"
echo ""
echo "Next steps:"
echo "1. cd infra"
echo "2. terraform init -backend-config=backend-config.hcl"
echo "3. terraform plan"
echo "4. terraform apply"
