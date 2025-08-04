import json
import boto3
import os
import urllib.parse
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda function to invalidate CloudFront cache when objects are created in S3
    Supports multiple S3 buckets mapped to different CloudFront distributions
    """
    
    # Initialize CloudFront client
    cloudfront = boto3.client('cloudfront')
    
    # Get bucket to distribution mapping from environment variable
    bucket_distribution_mapping = json.loads(os.environ['BUCKET_DISTRIBUTION_MAPPING'])
    
    # Parse S3 event
    try:
        # Group object keys by bucket
        bucket_objects = {}
        
        for record in event['Records']:
            # Get bucket name and object key
            bucket_name = record['s3']['bucket']['name']
            object_key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
            
            if bucket_name not in bucket_objects:
                bucket_objects[bucket_name] = []
            
            bucket_objects[bucket_name].append('/' + object_key)
            print(f"Object created in bucket {bucket_name}: {object_key}")
        
        if not bucket_objects:
            print("No objects to invalidate")
            return {
                'statusCode': 200,
                'body': json.dumps('No objects to invalidate')
            }
        
        invalidation_results = []
        
        # Process each bucket separately
        for bucket_name, object_keys in bucket_objects.items():
            # Get the corresponding CloudFront distribution ID
            if bucket_name not in bucket_distribution_mapping:
                print(f"Warning: No CloudFront distribution mapping found for bucket {bucket_name}")
                continue
            
            distribution_id = bucket_distribution_mapping[bucket_name]
            
            # Create invalidation for this distribution
            invalidation_batch = {
                'Paths': {
                    'Quantity': len(object_keys),
                    'Items': object_keys
                },
                'CallerReference': f"lambda-invalidation-{bucket_name}-{datetime.now().isoformat()}"
            }
            
            response = cloudfront.create_invalidation(
                DistributionId=distribution_id,
                InvalidationBatch=invalidation_batch
            )
            
            invalidation_id = response['Invalidation']['Id']
            
            print(f"CloudFront invalidation created for {bucket_name}: {invalidation_id}")
            print(f"Distribution ID: {distribution_id}")
            print(f"Invalidated paths: {object_keys}")
            
            invalidation_results.append({
                'bucket_name': bucket_name,
                'distribution_id': distribution_id,
                'invalidation_id': invalidation_id,
                'paths': object_keys
            })
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'CloudFront invalidations created successfully',
                'invalidations': invalidation_results
            })
        }
        
    except Exception as e:
        print(f"Error creating CloudFront invalidation: {str(e)}")
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Failed to create CloudFront invalidation',
                'details': str(e)
            })
        }