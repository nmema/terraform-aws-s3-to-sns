import boto3
import json
import logging
import os


s3_client = boto3.client('s3')
dynamodb_client = boto3.client('dynamodb')
ses_client = boto3.client('ses')

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def lambda_handler(event, context):
    logger.info(f'Event: {event}')

    record = event["Records"][0]
    bucket_name = record['s3']['bucket']['name']
    object_key = record['s3']['object']['key']

    # Get object tags
    response = s3_client.get_object_tagging(Bucket=bucket_name, Key=object_key)
    tags = {tag['Key']: tag['Value'] for tag in response.get('TagSet', [])}
    owner = tags.get('Owner', 'Unknown')

    # Fetch email recipients from DynamoDB
    try:
        response = dynamodb_client.get_item(
            TableName=os.environ['DDB_TABLE_NAME'],
            Key={'Owner': {'S': owner}}
        )
        email_addresses = [email['S'] for email in response['Item']['Emails']['L']]

    except Exception as e:
        logger.error(f'No emails found for Owner "{owner}": {e}')
        return {'statusCode': 200, 'body': f'No emails found for {owner}'}

    if not email_addresses:
        logger.warning(f'No email recipients found for {owner}.')
        return {'statusCode': 200, 'body': 'No recipients available.'}

    # Construct email content
    subject = 'S3 Upload Notification'
    body = f'''
    S3 Upload Successful!
    
    📌 File Path: s3://{bucket_name}/{object_key}
    📂 File Name: {object_key.split('/')[-1]}
    🏷 Tags: {json.dumps(tags, indent=2)}

    ✅ This is an automated notification.
    '''

    # Send Email via SES
    try:
        response = ses_client.send_email(
            Source=os.environ['SES_SENDER_EMAIL'],
            Destination={'ToAddresses': email_addresses},
            Message={
                'Subject': {'Data': subject},
                'Body': {'Text': {'Data': body}}
            }
        )

        logger.info(f'Email sent to {email_addresses}: {response}')

    except Exception as e:
        logger.error(f'Failed to send email: {e}')

    return {'statusCode': 200, 'body': 'S3 upload logged and email notification sent!'}
