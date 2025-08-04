output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.cloudfront_invalidation.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.cloudfront_invalidation.arn
}

output "configured_buckets" {
  description = "List of S3 buckets configured with CloudFront invalidation"
  value       = keys(var.bucket_distribution_mapping)
}

output "bucket_distribution_mapping" {
  description = "Complete mapping of buckets to CloudFront distributions"
  value = {
    for bucket_name, config in var.bucket_distribution_mapping : bucket_name => {
      cloudfront_distribution_id = config.cloudfront_distribution_id
      prefix_filter             = config.prefix_filter
      suffix_filter             = config.suffix_filter
    }
  }
}