#!/bin/bash
# This script sets up a NAT Gateway with a public Elastic IP for outbound internet access in a specified subnet.

# Disable AWS CLI pager to prevent interruptions
export AWS_PAGER=""

# Variables (Replace these with your specific values)
SUBNET_ID="subnet-04297d514d5cac04d"   # Replace with your Subnet ID
REGION="us-west-2"                     # Replace with your AWS Region

# Step 1: Allocate a new Elastic IP
echo "Allocating a new Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address --region $REGION --query 'AllocationId' --output text)

if [ -z "$ALLOCATION_ID" ]; then
    echo "Failed to allocate Elastic IP. Exiting."
    exit 1
fi

echo "Elastic IP allocated with Allocation ID: $ALLOCATION_ID"

# Step 2: Create a NAT Gateway
echo "Creating NAT Gateway..."
NAT_GATEWAY_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $SUBNET_ID \
    --allocation-id $ALLOCATION_ID \
    --region $REGION \
    --query 'NatGateway.NatGatewayId' --output text)

if [ -z "$NAT_GATEWAY_ID" ]; then
    echo "Failed to create NAT Gateway. Exiting."
    exit 1
fi

echo "NAT Gateway created with ID: $NAT_GATEWAY_ID"

# Step 3: Wait for the NAT Gateway to become available
echo "Waiting for NAT Gateway to be available..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GATEWAY_ID --region $REGION

echo "NAT Gateway is now available."

# Step 4: Output Details
echo "NAT Gateway Details:"
aws ec2 describe-nat-gateways --nat-gateway-ids $NAT_GATEWAY_ID --region $REGION --no-paginate

# Done
echo "NAT Gateway and Elastic IP setup complete."
echo "Elastic IP Allocation ID: $ALLOCATION_ID"
echo "NAT Gateway ID: $NAT_GATEWAY_ID"