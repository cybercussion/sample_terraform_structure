#!/bin/bash
# This script removes a NAT Gateway and releases the associated public Elastic IP to clean up resources i.e. $3.60 or so a month

# Disable AWS CLI pager to prevent interruptions
export AWS_PAGER=""

# Variables (Replace with your specific values)
SUBNET_ID="subnet-04297d514d5cac04d"  # Replace with your subnet ID
REGION="us-west-2"                    # Replace with your AWS region

# Step 1: Retrieve the NAT Gateway ID
echo "Retrieving NAT Gateway ID for subnet: $SUBNET_ID..."
NAT_GATEWAY_ID=$(aws ec2 describe-nat-gateways \
    --filter "Name=subnet-id,Values=$SUBNET_ID" \
    --region $REGION \
    --query "NatGateways[0].NatGatewayId" --output text)

if [ "$NAT_GATEWAY_ID" == "None" ]; then
    echo "No NAT Gateway found in subnet: $SUBNET_ID. Exiting."
    exit 1
fi

echo "NAT Gateway ID found: $NAT_GATEWAY_ID"

# Step 2: Retrieve the Elastic IP Allocation ID
echo "Retrieving Elastic IP Allocation ID associated with NAT Gateway: $NAT_GATEWAY_ID..."
ALLOCATION_ID=$(aws ec2 describe-nat-gateways \
    --nat-gateway-ids $NAT_GATEWAY_ID \
    --region $REGION \
    --query "NatGateways[0].NatGatewayAddresses[0].AllocationId" --output text)

if [ "$ALLOCATION_ID" == "None" ]; then
    echo "No Elastic IP found for NAT Gateway: $NAT_GATEWAY_ID. Exiting."
    exit 1
fi

echo "Elastic IP Allocation ID found: $ALLOCATION_ID"

# Step 3: Delete the NAT Gateway
echo "Deleting NAT Gateway with ID: $NAT_GATEWAY_ID..."
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GATEWAY_ID --region $REGION

echo "Waiting for NAT Gateway to be deleted..."
aws ec2 wait nat-gateway-deleted --nat-gateway-ids $NAT_GATEWAY_ID --region $REGION

echo "NAT Gateway deleted."

# Step 4: Release the Elastic IP
echo "Releasing Elastic IP with Allocation ID: $ALLOCATION_ID..."
aws ec2 release-address --allocation-id $ALLOCATION_ID --region $REGION || {
    echo "Elastic IP already released or not found. Skipping."
}

# Step 5: Verify Cleanup
echo "Verifying cleanup..."
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --region $REGION || echo "NAT Gateway cleanup verified."
aws ec2 describe-addresses --allocation-ids $ALLOCATION_ID --region $REGION || echo "Elastic IP cleanup verified."

echo "Teardown complete."