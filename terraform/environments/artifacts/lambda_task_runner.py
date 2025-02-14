import os
import json
import time
import logging
import traceback
import boto3
from botocore.exceptions import ClientError

# Setup structured logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize DynamoDB
dynamodb = boto3.resource('dynamodb')

# Get the DynamoDB table name from environment variables
DYNAMODB_TABLE_NAME = os.environ.get('DYNAMODB_TABLE_NAME')

if not DYNAMODB_TABLE_NAME:
    logger.error("Environment variable 'DYNAMODB_TABLE_NAME' is not set. Exiting.")
    raise EnvironmentError("DYNAMODB_TABLE_NAME environment variable not set")

logger.info(f"Using DynamoDB table: {DYNAMODB_TABLE_NAME}")

# DynamoDB table reference
table = dynamodb.Table(DYNAMODB_TABLE_NAME)

def handler(event, context):
    try:
        # Process each record in the batch
        for record in event['Records']:
            # Parse the message body
            message = json.loads(record['body'])
            task_id = message.get('taskId')

            if not task_id:
                logger.error("Task does not have a 'taskId'. Skipping.")
                continue

            # Update DynamoDB: Mark task as "processing"
            update_task_status(task_id, "processing")

            try:
                # Simulate task execution
                process_task(message)

                # Update DynamoDB: Mark task as "completed"
                update_task_status(task_id, "completed")
                logger.info(f"Task {task_id} marked as completed.")
            except Exception as task_error:
                # Update DynamoDB: Mark task as "error"
                update_task_status(task_id, "error")
                logger.error(f"Failed to process task {task_id}: {task_error}")

        return {
            "statusCode": 200,
            "body": json.dumps({"message": "All tasks processed successfully."}),
        }

    except Exception as e:
        # Log the error and stack trace for debugging
        logger.error(f"Error processing task batch: {e}")
        logger.error("Stack Trace: %s", traceback.format_exc())
        
        return {
            "statusCode": 500,
            "body": json.dumps({"message": "Failed to process tasks.", "error": str(e)}),
        }


def process_task(task):
    """
    Simulates task execution. Replace this logic with the actual task processing logic.
    """
    try:
        logger.info(f"Started processing task: {task}")
        time.sleep(20)  # Simulate task processing for 20 seconds
        logger.info(f"Completed processing task: {task}")

    except Exception as e:
        # Log errors within the task processing
        logger.error(f"Error in processing task: {task}, error: {e}")
        raise  # Rethrow the exception so the handler can catch it


def update_task_status(task_id, status):
    """
    Updates the status of a task in DynamoDB.
    Adds an expiration_time attribute if the status is 'completed'.
    """
    try:
        # Calculate expiration time for completed tasks (24 hours from now)
        expiration_time = int(time.time()) + 86400  # 86400 seconds = 24 hours

        update_expression = 'SET #s = :status'
        expression_values = {':status': status}
        expression_names = {'#s': 'status'}

        # Add expiration_time only for completed tasks
        if status == 'completed':
            update_expression += ', #e = :expiration_time'
            expression_values[':expiration_time'] = expiration_time
            expression_names['#e'] = 'expiration_time'

        table.update_item(
            Key={'taskId': task_id},
            UpdateExpression=update_expression,
            ExpressionAttributeNames=expression_names,
            ExpressionAttributeValues=expression_values
        )
        logger.info(f"Updated task {task_id} to status '{status}'.")
    except ClientError as e:
        logger.error(f"Failed to update task {task_id} to status '{status}': {e}")
        raise