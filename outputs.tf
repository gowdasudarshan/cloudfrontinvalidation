output "lambda_function_name" {
  description = "Name of the CloudFront invalidation Lambda function"
  value       = aws_lambda_function.cloudfront_invalidation.function_name
}