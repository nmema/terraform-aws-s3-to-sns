import json
import boto3
import logging


client = boto3.client('s3')

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f'Event: {event}')

    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        object_key = record['s3']['object']['key']

        # Get object tags
        response = client.get_object_tagging(Bucket=bucket_name, Key=object_key)
        tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}

        # Log information
        logger.info(f'File uploaded: s3://{bucket_name}/{object_key}')
        logger.info(f'File Name: {object_key.split('/')[-1]}')
        logger.info(f'Tags: {tags}')

    return {'statusCode': 200, 'body': json.dumps('Logged S3 upload successfully!')}
