import http.client
import json
import os
import urllib.parse

def lambda_handler(event, context):
    # Extract the SNS message
    sns_message = event['Records'][0]['Sns']['Message']
    alarm_message = json.loads(sns_message)

    # Format the message for Google Chat
    formatted_message = format_cw_alert(alarm_message)

    # Send the formatted message to Google Chat
    send_to_google_chat(formatted_message)

def send_to_google_chat(formatted_message):
    url = os.environ['GOOGLE_CHAT_WEBHOOK']
    payload = {'text': formatted_message}
    json_payload = json.dumps(payload)
    headers = {'Content-Type': 'application/json'}
    
    # HTTPS connection
    conn = http.client.HTTPSConnection("chat.googleapis.com")
    try:
        conn.request('POST', url, body=json_payload, headers=headers)
        response = conn.getresponse()
        # Check the response status code
        if response.status >= 400:
            # Handle non-OK response
            print(f"Error: {response.status} {response.reason}")
            error_response = json.loads(response.read().decode('utf-8'))
            print("Error Response:", error_response)

        # Read and process the response
        res = response.read().decode('utf-8')
        return res

    except http.client.HTTPException as e:
        # Handle HTTP exceptions
        print("HTTP exception occurred:", str(e))

    except ConnectionError as e:
        # Handle connection errors
        print("Connection error occurred:", str(e))

    except Exception as e:
        # Handle other exceptions
        print("An error occurred:", str(e))
    finally:
        conn.close()

def format_cw_alert(alarm_message):
    # Retrieve environment variables
    aws_region = os.environ['AWS_REGION']
    aws_account_id = os.environ['AWS_ACCOUNT_ID']

    # Basic alarm details
    alarm_name_full = alarm_message.get('AlarmName', 'N/A')
    alarm_state = alarm_message.get('NewStateValue', '')

    # Determine the title based on the alarm state
    if alarm_state == "OK":
        title = "✅ Recovery: CloudWatch Notification"
    else:
        title = "🚨 Alert: CloudWatch Notification"

    alarm_name = f"*Alarm Name*: {alarm_name_full}"
    description = f"*Description*: {alarm_message.get('AlarmDescription', 'No description provided.')}"
    state_change = f"*State Change*: {alarm_message.get('OldStateValue', 'Unknown')} to {alarm_message.get('NewStateValue', 'Unknown')}"

    # Metric details
    trigger = alarm_message.get('Trigger', {})
    metric_name = trigger.get('MetricName', 'Unknown metric')
    threshold = trigger.get('Threshold', 'Unknown threshold')
    metric_and_threshold = f"*Metric/Threshold*: {metric_name} crossed {threshold}"

    # Time of the alert
    time = f"*Time*: {alarm_message.get('StateChangeTime', 'Unknown time')}"

    # Extract service name from alarm name
    try:
        service_name = '-'.join(alarm_name_full.split('-')[1:-1])
    except IndexError:
        service_name = 'unknown-service'

    # Construct URLs
    dashboard_url = f"https://console.aws.amazon.com/cloudwatch/home?region={aws_region}#alarmsV2:alarm/{alarm_name_full}"

    # Use Google Chat link formatting
    message_content = (
        f"{title}\n"
        f"{alarm_name}\n"
        f"{description}\n"
        f"{state_change}\n"
        f"{metric_and_threshold}\n"
        f"{time}\n\n"
        f"<{dashboard_url}|View in CloudWatch Dashboard>\n"
    )

    return message_content
