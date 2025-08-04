# Data sources for existing resources
data "aws_s3_bucket" "existing_buckets" {
  for_each = var.bucket_distribution_mapping
  bucket   = each.key
}

data "aws_cloudfront_distribution" "existing_distributions" {
  for_each = var.bucket_distribution_mapping
  id       = each.value.cloudfront_distribution_id
}

# IAM role for Lambda function
resource "aws_iam_role" "lambda_role" {
  name = "cloudfront-invalidation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for CloudFront invalidation
resource "aws_iam_policy" "cloudfront_invalidation_policy" {
  name        = "cloudfront-invalidation-policy"
  description = "Policy to allow CloudFront cache invalidation"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudfront:CreateInvalidation"
        ]
        Resource = [
          for dist in data.aws_cloudfront_distribution.existing_distributions : dist.arn
        ]
      }
    ]
  })
}

# IAM policy for CloudWatch logging
resource "aws_iam_policy" "lambda_logging_policy" {
  name        = "lambda-logging-policy"
  description = "Policy to allow Lambda to write logs to CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# Attach policies to Lambda role
resource "aws_iam_role_policy_attachment" "lambda_cloudfront_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.cloudfront_invalidation_policy.arn
}

resource "aws_iam_role_policy_attachment" "lambda_logging_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_logging_policy.arn
}

# Create deployment package for Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "lambda_function.py"
  output_path = "lambda_function.zip"
}

# Lambda function
resource "aws_lambda_function" "cloudfront_invalidation" {
  filename         = "lambda_function.zip"
  function_name    = "cloudfront-cache-invalidation"
  role            = aws_iam_role.lambda_role.arn
  handler         = "lambda_function.lambda_handler"
  runtime         = "python3.9"
  timeout         = 60

  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  environment {
    variables = {
      BUCKET_DISTRIBUTION_MAPPING = jsonencode({
        for bucket_name, config in var.bucket_distribution_mapping : bucket_name => config.cloudfront_distribution_id
      })
    }
  }
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${aws_lambda_function.cloudfront_invalidation.function_name}"
  retention_in_days = 14
}

# Lambda permissions to allow S3 buckets to invoke the function
resource "aws_lambda_permission" "allow_s3" {
  for_each      = var.bucket_distribution_mapping
  statement_id  = "AllowExecutionFromS3Bucket-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.cloudfront_invalidation.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = data.aws_s3_bucket.existing_buckets[each.key].arn
}

# S3 bucket notifications
resource "aws_s3_bucket_notification" "bucket_notifications" {
  for_each = var.bucket_distribution_mapping
  bucket   = data.aws_s3_bucket.existing_buckets[each.key].id

  lambda_function {
    lambda_function_arn = aws_lambda_function.cloudfront_invalidation.arn
    events              = ["s3:ObjectCreated:*"]
    
    # Add optional prefix and suffix filters
    filter_prefix = each.value.prefix_filter != "" ? each.value.prefix_filter : null
    filter_suffix = each.value.suffix_filter != "" ? each.value.suffix_filter : null
  }

  depends_on = [aws_lambda_permission.allow_s3]
}