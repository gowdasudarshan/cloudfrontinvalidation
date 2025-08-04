# CloudFront Invalidation Lambda Function

This Terraform configuration sets up a Lambda function that automatically invalidates CloudFront cache when objects are created in an S3 bucket.

## Components

- **Lambda Function**: Node.js function that creates CloudFront invalidations
- **S3 Event Notification**: Triggers Lambda when objects are created in the bucket
- **IAM Role & Policies**: Permissions for CloudFront invalidation and CloudWatch logging
- **Lambda Permission**: Allows S3 to invoke the Lambda function

## Prerequisites

- Existing S3 bucket
- Existing CloudFront distribution
- Terraform installed and configured with AWS credentials

## Usage

1. **Install dependencies and create Lambda package**:
   ```bash
   npm install
   npm run zip
   ```

2. **Set your variables**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your actual values
   ```

3. **Initialize and apply Terraform**:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Variables

- `bucket_name`: Name of the existing S3 bucket
- `cloudfront_distribution_id`: ID of the existing CloudFront distribution

## Outputs

- `lambda_function_name`: Name of the created Lambda function

## How it works

1. When an object is created in the S3 bucket, it triggers an S3 event notification
2. The event notification invokes the Lambda function
3. The Lambda function creates a CloudFront invalidation for the specific object path
4. CloudFront cache is invalidated and the new content is served on subsequent requests