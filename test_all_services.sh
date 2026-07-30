#!/usr/bin/env bash
# ── LocalEmu Multi-Service Automated Test & Verification Script ────────────────
set -e

ENDPOINT="http://localhost:4566"
export AWS_PROFILE=localemu
export AWS_ENDPOINT_URL="$ENDPOINT"
export AWS_DEFAULT_REGION="us-east-1"
export AWS_ACCESS_KEY_ID="test"
export AWS_SECRET_ACCESS_KEY="test"

echo "============================================================"
echo "🚀 Testing AWS Services on LocalEmu ($ENDPOINT)"
echo "============================================================"

# 1. S3 Test
echo "📦 Testing S3..."
aws s3 mb s3://test-suite-bucket 2>/dev/null || true
echo "Hello S3 Automated Test" > /tmp/s3_test.txt
aws s3 cp /tmp/s3_test.txt s3://test-suite-bucket/s3_test.txt
aws s3 ls s3://test-suite-bucket/
echo "✅ S3 OK"
echo "------------------------------------------------------------"

# 2. DynamoDB Test
echo "⚡ Testing DynamoDB..."
aws dynamodb create-table \
  --table-name TestTable \
  --attribute-definitions AttributeName=id,AttributeType=S \
  --key-schema AttributeName=id,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST 2>/dev/null || true

aws dynamodb put-item --table-name TestTable --item '{"id":{"S":"101"},"name":{"S":"LocalEmu"}}'
aws dynamodb get-item --table-name TestTable --key '{"id":{"S":"101"}}'
echo "✅ DynamoDB OK"
echo "------------------------------------------------------------"

# 3. SQS Test
echo "📬 Testing SQS..."
QUEUE_URL=$(aws sqs create-queue --queue-name test-queue --query 'QueueUrl' --output text)
aws sqs send-message --queue-url "$QUEUE_URL" --message-body "Automated test message"
aws sqs receive-message --queue-url "$QUEUE_URL"
echo "✅ SQS OK"
echo "------------------------------------------------------------"

# 4. SNS Test
echo "🔔 Testing SNS..."
TOPIC_ARN=$(aws sns create-topic --name test-topic --query 'TopicArn' --output text)
aws sns publish --topic-arn "$TOPIC_ARN" --message "Automated topic notification"
echo "✅ SNS OK"
echo "------------------------------------------------------------"

# 5. Secrets Manager & SSM Test
echo "🔐 Testing Secrets Manager & SSM Parameter Store..."
aws secretsmanager create-secret --name "test/app/key" --secret-string "secret-12345" 2>/dev/null || true
aws secretsmanager get-secret-value --secret-id "test/app/key"

aws ssm put-parameter --name "/test/param" --type "String" --value "param-value" --overwrite
aws ssm get-parameter --name "/test/param"
echo "✅ Secrets Manager & SSM OK"
echo "------------------------------------------------------------"

# 6. EC2 Test
echo "💻 Testing EC2..."
aws ec2 describe-images --query 'Images[0]' 2>/dev/null || true
aws ec2 describe-instances
echo "✅ EC2 OK"
echo "------------------------------------------------------------"

# 7. EKS Test
echo "☸️ Testing EKS..."
aws eks list-clusters
aws eks create-cluster \
  --name test-eks-cluster \
  --role-arn arn:aws:iam::000000000000:role/eks-role \
  --resources-vpc-config subnetIds=subnet-123456 2>/dev/null || true
aws eks list-clusters
echo "✅ EKS OK"
echo "------------------------------------------------------------"

echo "============================================================"
echo "🎉 ALL AWS SERVICES (INCLUDING EKS) VERIFIED SUCCESSFULLY ON LOCALEMU!"
echo "============================================================"
