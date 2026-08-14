import json
import boto3
import base64
import os
from datetime import datetime
import uuid

TABLE_NAME = os.environ.get('TABLE_NAME')
BUCKET_NAME = os.environ.get('BUCKET_NAME')
ADMIN_EMAIL = os.environ.get('ADMIN_EMAIL')
REGION = os.environ.get('REGION', 'us-east-1')

dynamodb = boto3.resource('dynamodb', region_name=REGION)
s3 = boto3.client('s3', region_name=REGION)
ses = boto3.client('ses', region_name=REGION)


def lambda_handler(event, context):
    print("Event received:", json.dumps(event))

    if event.get('httpMethod') == 'OPTIONS':
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            }
        }

    try:
        if 'body' in event:
            body = json.loads(event['body'])
        elif 'name' in event and 'email' in event:
            body = event
        else:
            return {
                'statusCode': 400,
                'headers': {'Access-Control-Allow-Origin': '*'},
                'body': json.dumps({'message': 'Invalid request format.'})
            }

        feedback_id = str(uuid.uuid4())
        name = body.get('name')
        email = body.get('email')
        message = body.get('message')
        file_base64 = body.get('file_base64')

        file_url = None
        if file_base64:
            key = f"{feedback_id}.pdf"
            pdf_data = base64.b64decode(file_base64.split(',')[-1])

            s3.put_object(
                Bucket=BUCKET_NAME,
                Key=key,
                Body=pdf_data,
                ContentType='application/pdf'
            )

            file_url = s3.generate_presigned_url(
                'get_object',
                Params={'Bucket': BUCKET_NAME, 'Key': key},
                ExpiresIn=86400
            )

        table = dynamodb.Table(TABLE_NAME)
        table.put_item(Item={
            'feedback_id': feedback_id,
            'name': name,
            'email': email,
            'message': message,
            'file_url': file_url,
            'timestamp': datetime.utcnow().isoformat()
        })

        response = ses.send_email(
            Source=ADMIN_EMAIL,
            Destination={'ToAddresses': [ADMIN_EMAIL]},
            Message={
                'Subject': {'Data': 'New Feedback Received'},
                'Body': {
                    'Html': {
                        'Data': f"""
                        <html>
                        <body>
                          <h2>New Feedback Received</h2>
                          <p><b>Name:</b> {name}</p>
                          <p><b>Email:</b> {email}</p>
                          <p><b>Message:</b> {message}</p>
                          {f'<p><a href="{file_url}">View PDF Attachment</a></p>' if file_url else ''}
                        </body>
                        </html>
                        """
                    }
                }
            }
        )

        print(f"SES Email sent. Message ID: {response['MessageId']}")

        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': '*',
                'Access-Control-Allow-Methods': 'POST,OPTIONS'
            },
            'body': json.dumps({'message': 'Feedback submitted successfully'})
        }

    except Exception as e:
        print("Error occurred:", str(e))
        return {
            'statusCode': 500,
            'headers': {'Access-Control-Allow-Origin': '*'},
            'body': json.dumps({'message': 'Internal server error', 'error': str(e)})
        }