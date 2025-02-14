#!/bin/bash

# Check if outputs.env exists
if [[ -f outputs.env ]]; then
  echo "outputs.env already exists. Skipping Terragrunt output generation."
else
  # Generate outputs.env from Terragrunt outputs
  echo "Generating outputs.env from Terragrunt outputs..."
  terragrunt run-all output | sed 's/ = /=/g' > outputs.env
fi

# Source the outputs.env file
echo "Loading outputs from outputs.env..."
source outputs.env

# Validate if the base URL is loaded
if [[ -z "$api_endpoint" ]]; then
  echo "Error: API Gateway base URL is missing. Check your Terraform outputs."
  exit 1
fi

# API Gateway Stage
API_STAGE="${stage_name:-dev}"

# Define endpoints
CREATE_TASK_URL="${api_endpoint}/task"
TASK_STATUS_URL="${api_endpoint}/task"

echo "Base URL: $api_endpoint"
echo "Create Task URL: $CREATE_TASK_URL"
echo "Task Status URL: $TASK_STATUS_URL"

# Create a task
echo "Creating a task..."
TASK_RESPONSE=$(curl -s -X POST \
  -H "Content-Type: application/json" \
  -d '{"key1": "value1", "key2": "value2"}' \
  "$CREATE_TASK_URL")

echo "Task creation response: $TASK_RESPONSE"

# Extract Task ID from the response (adjust this based on the actual response)
TASK_ID=$(echo "$TASK_RESPONSE" | jq -r '.taskId')

if [ -z "$TASK_ID" ] || [ "$TASK_ID" == "null" ]; then
  echo "Failed to retrieve Task ID. Exiting."
  exit 1
fi

echo "Task ID: $TASK_ID"

# Poll the status of the task
echo "Checking task status..."

STATUS="pending"
RETRIES=0
MAX_RETRIES=30  # Retry limit (e.g., 30 attempts)

while [[ "$STATUS" == "pending" || "$STATUS" == "processing" ]] && [ $RETRIES -lt $MAX_RETRIES ]; do
  STATUS_RESPONSE=$(curl -s -X GET "$TASK_STATUS_URL/$TASK_ID")
  
  # Debugging: Print the entire response for inspection
  # echo "DEBUG: Status response: $STATUS_RESPONSE"
  
  # Extract the status from the response
  STATUS=$(echo "$STATUS_RESPONSE" | jq -r '.status')

  # Handle missing or null status values
  if [ -z "$STATUS" ] || [ "$STATUS" == "null" ]; then
    echo "Error: Task status not found or invalid. Exiting."
    exit 1
  fi

  # Handle unexpected status values
  case "$STATUS" in
    "completed")
      #echo "Task completed successfully."
      break
      ;;
    "error")
      echo "Task failed. Please check the logs for more details."
      exit 1
      ;;
    "pending" | "processing")
      echo "Status is still $STATUS, retrying..."
      RETRIES=$((RETRIES+1))
      sleep 2
      ;;
    *)
      echo "Unexpected status: $STATUS. Exiting."
      exit 1
      ;;
  esac
done

if [ $RETRIES -ge $MAX_RETRIES ]; then
  echo "Error: Max retries reached. Task is still pending or processing. Exiting."
  exit 1
fi

echo "Task completed successfully!"