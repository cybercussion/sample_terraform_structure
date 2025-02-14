# Lambda SQS Task Runner Demo

## DNA

1. Lambda Endpoint - task (POST) and tast/{taskId} (GET)
2. Posts to SQS Queue and sets a Task Id
3. Task Runner picks this up (triggered) and processes it.
4. Integrate with polling or websocket for UI
   1. Polling SQS directly is not recommended
      1. consider S3 or DynamoDB
   2. Lambda needs permissions to write to #1 decision.
   3. May need to pass dependencies into Lambda thru env vars

- Keeps APIs snappy - no long timeouts like 1200s +
- Keeps task running via Lambda or ECS/Fargate or EC2
- Divide and conquer with Task Runner filters that will only process certain messages.
