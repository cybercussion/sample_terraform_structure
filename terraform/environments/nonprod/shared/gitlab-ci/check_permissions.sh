#!/bin/bash

# Disable AWS CLI pager
export AWS_PAGER=""

# Variables
# Get the current user's ARN
IAM_ARN=$(aws sts get-caller-identity --query "Arn" --output text)
if [ -z "$IAM_ARN" ]; then
    echo "❌ Failed to retrieve IAM ARN. Check your AWS CLI configuration."
    exit 1
fi
REGION="us-west-2"

# Actions to check
ACTIONS=(
    # EC2 and NAT Gateway
    "ec2:ReleaseAddress"
    "ec2:DeleteNatGateway"
    "ec2:DisassociateAddress"
    "ec2:Describe*"
    # Elastic Load Balancer
    "elasticloadbalancing:*"
    # EKS
    "eks:CreateCluster"
    "eks:DeleteCluster"
    "eks:DescribeCluster"
    "eks:UpdateClusterConfig"
    # Amazon ECR
    "ecr:GetAuthorizationToken"
    "ecr:BatchCheckLayerAvailability"
    "ecr:GetDownloadUrlForLayer"
    "ecr:BatchGetImage"
    "ecr:InitiateLayerUpload"
    "ecr:UploadLayerPart"
    "ecr:CompleteLayerUpload"
    "ecr:PutImage"
    # CloudWatch Logs
    "logs:CreateLogGroup"
    "logs:CreateLogStream"
    "logs:PutLogEvents"
)

# Simulate actions
echo "Checking permissions for IAM principal: $IAM_ARN"
for ACTION in "${ACTIONS[@]}"; do
    RESULT=$(aws iam simulate-principal-policy \
        --policy-source-arn $IAM_ARN \
        --action-names $ACTION \
        --region $REGION \
        --query 'EvaluationResults[0].EvalDecision' --output text)

    if [ "$RESULT" == "allowed" ]; then
        echo "✅ Permission granted for action: $ACTION"
    else
        echo "❌ Permission denied for action: $ACTION"
    fi
done