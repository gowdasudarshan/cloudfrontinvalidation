variable "bucket_distribution_mapping" {
  description = "Map of S3 bucket names to their corresponding CloudFront distribution IDs"
  type = map(object({
    cloudfront_distribution_id = string
    prefix_filter             = optional(string, "")  # Optional: filter S3 events by object key prefix
    suffix_filter             = optional(string, "")  # Optional: filter S3 events by object key suffix
  }))
  
  # Example:
  # bucket_distribution_mapping = {
  #   "my-website-bucket" = {
  #     cloudfront_distribution_id = "E1234567890ABC"
  #     prefix_filter             = "assets/"
  #     suffix_filter             = ""
  #   }
  #   "my-api-bucket" = {
  #     cloudfront_distribution_id = "E0987654321XYZ"
  #   }
  # }
}