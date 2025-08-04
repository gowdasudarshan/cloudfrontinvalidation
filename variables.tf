variable "bucket_name" {
  description = "Name of the existing S3 bucket"
  type        = string
}

variable "cloudfront_distribution_id" {
  description = "ID of the existing CloudFront distribution"
  type        = string
}