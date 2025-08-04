const AWS = require('aws-sdk');

const cloudfront = new AWS.CloudFront();

exports.handler = async (event) => {
    console.log('Event:', JSON.stringify(event, null, 2));
    
    try {
        // Get the CloudFront distribution ID from environment variables
        const distributionId = process.env.CLOUDFRONT_DISTRIBUTION_ID;
        
        if (!distributionId) {
            throw new Error('CLOUDFRONT_DISTRIBUTION_ID environment variable is not set');
        }
        
        // Process each S3 event record
        for (const record of event.Records) {
            const bucketName = record.s3.bucket.name;
            const objectKey = decodeURIComponent(record.s3.object.key.replace(/\+/g, ' '));
            
            console.log(`Processing object: ${objectKey} from bucket: ${bucketName}`);
            
            // Create CloudFront invalidation
            const invalidationParams = {
                DistributionId: distributionId,
                InvalidationBatch: {
                    CallerReference: `s3-invalidation-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
                    Paths: {
                        Quantity: 1,
                        Items: [`/${objectKey}`]
                    }
                }
            };
            
            console.log('Creating CloudFront invalidation with params:', JSON.stringify(invalidationParams, null, 2));
            
            const result = await cloudfront.createInvalidation(invalidationParams).promise();
            
            console.log('CloudFront invalidation created successfully:', JSON.stringify(result, null, 2));
        }
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'CloudFront invalidation completed successfully'
            })
        };
        
    } catch (error) {
        console.error('Error creating CloudFront invalidation:', error);
        throw error;
    }
};