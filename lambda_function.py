import json
import boto3
import os
import urllib.parse
from datetime import datetime

def lambda_handler(event, context):
    """
    Lambda function to invalidate CloudFront cache when objects are created in S3
    """
    
    # Initialize CloudFront client
    cloudfront = boto3.client('cloudfront')
    
    # Get CloudFront distribution ID from environment variable
    distribution_id = os.environ['CLOUDFRONT_DISTRIBUTION_ID']
    
    # Parse S3 event
    try:
        # Extract object keys from S3 event
        object_keys = []
        
        for record in event['Records']:
            # Get the object key and decode URL encoding
            object_key = urllib.parse.unquote_plus(record['s3']['object']['key'], encoding='utf-8')
            object_keys.append('/' + object_key)
            
            print(f"Object created: {object_key}")
        
        if not object_keys:
            print("No objects to invalidate")
            return {
                'statusCode': 200,
                'body': json.dumps('No objects to invalidate')
            }
        
        # Create invalidation
        invalidation_batch = {
            'Paths': {
                'Quantity': len(object_keys),
                'Items': object_keys
            },
            'CallerReference': f"lambda-invalidation-{datetime.now().isoformat()}"
        }
        
        response = cloudfront.create_invalidation(
            DistributionId=distribution_id,
            InvalidationBatch=invalidation_batch
        )
        
        invalidation_id = response['Invalidation']['Id']
        
        print(f"CloudFront invalidation created: {invalidation_id}")
        print(f"Invalidated paths: {object_keys}")
        
        return {
            'statusCode': 200,
            'body': json.dumps({
                'message': 'CloudFront invalidation created successfully',
                'invalidation_id': invalidation_id,
                'paths': object_keys
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