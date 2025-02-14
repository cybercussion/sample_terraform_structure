import json
import boto3
import os
import logging
import time
from botocore.exceptions import ClientError

# Initialize AWS clients
sqs = boto3.client('sqs')
dynamodb = boto3.resource('dynamodb')

# Environment variables
QUEUE_URL = os.environ.get('SQS_QUEUE_URL')
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')

# Set up logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Check environment variables
if not QUEUE_URL:
    logger.error("Environment variable 'SQS_QUEUE_URL' is not set. Exiting.")
    raise EnvironmentError("SQS_QUEUE_URL environment variable not set")

if not DYNAMODB_TABLE_NAME:
    logger.error("Environment variable 'DYNAMODB_TABLE_NAME' is not set. Exiting.")
    raise EnvironmentError("DYNAMODB_TABLE_NAME environment variable not set")

logger.info(f"Using SQS queue URL: {QUEUE_URL}")
logger.info(f"Using DynamoDB table: {DYNAMODB_TABLE_NAME}")

# DynamoDB table reference
table = dynamodb.Table(DYNAMODB_TABLE_NAME)


def handler(event, context):
    try:
        # Determine the HTTP method
        http_method = event.get('httpMethod', 'POST').upper()
        logger.info(f"HTTP Method: {http_method}")

        if http_method == "POST":
            return handle_post(event)
        elif http_method == "GET":
            return handle_get(event)
        else:
            logger.warning(f"Unsupported HTTP method: {http_method}")
            return {
                "statusCode": 405,
                "body": json.dumps({"message": f"HTTP method {http_method} is not allowed."}),
            }
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error.", "error": str(e)}),
        }


def handle_post(event):
    if 'body' not in event:
        logger.error("No 'body' field in the event")
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "'body' field is missing in the request"}),
        }

    try:
        body = json.loads(event['body'])
    except json.JSONDecodeError:
        logger.error("Invalid JSON in body: %s", event['body'])
        return {
            "statusCode": 400,
            "body": json.dumps({"message": "Invalid JSON in the request body"}),
        }

    try:
        # Generate a unique taskId
        task_id = str(int(time.time() * 1000))

        # Save task in DynamoDB with an initial status of "pending"
        table.put_item(
            Item={
                'taskId': task_id,
                'status': 'pending',
                'data': body
            }
        )
        logger.info(f"Task stored in DynamoDB. TaskId: {task_id}")

        # Send the message to SQS
        sqs_response = sqs.send_message(
            QueueUrl=QUEUE_URL,
            MessageBody=json.dumps({**body, "taskId": task_id})
        )
        logger.info(f"Message sent to SQS. MessageId: {sqs_response['MessageId']}")

        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Task successfully queued!",
                "taskId": task_id,
                "messageId": sqs_response['MessageId']
            }),
        }
    except ClientError as e:
        logger.error(f"Failed to process the task: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Failed to process the task.", "error": str(e)}),
        }


def handle_get(event):
    try:
        # Extract taskId from the path parameters
        path_params = event.get('pathParameters', {})
        task_id = path_params.get('taskId')

        if not task_id:
            logger.error("Missing 'taskId' path parameter.")
            return {
                "statusCode": 400,
                "body": json.dumps({"message": "Missing 'taskId' path parameter."}),
            }

        # Query DynamoDB for the task
        response = table.get_item(Key={'taskId': task_id}, ConsistentRead=True)
        task = response.get('Item')

        if not task:
            logger.info(f"TaskId {task_id} not found in DynamoDB.")
            return {
                "statusCode": 404,
                "body": json.dumps({
                    "message": "Task not found.",
                    "taskId": task_id
                }),
            }

        # Return the current status of the task
        return {
            "statusCode": 200,
            "body": json.dumps({
                "message": "Task retrieved successfully.",
                "taskId": task_id,
                "status": task['status'],
                "data": task.get('data', {})
            }),
        }

    except Exception as e:
        logger.error(f"Unexpected error in GET handler: {e}")
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Internal server error.", "error": str(e)}),
        }