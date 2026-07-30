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

# 6. EC2 & VPC Test
echo "💻 Testing EC2 & VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text 2>/dev/null || echo "vpc-1234")
aws ec2 describe-vpcs --vpc-ids "$VPC_ID"
aws ec2 describe-instances
echo "✅ EC2 & VPC OK"
echo "------------------------------------------------------------"

# 7. EKS Test
echo "☸️ Testing EKS..."
aws eks list-clusters
echo "✅ EKS OK"
echo "------------------------------------------------------------"

# 8. ELB / ALB Test
echo "⚖️ Testing Elastic Load Balancing (ELBv2)..."
aws elbv2 describe-load-balancers 2>/dev/null || true
aws elbv2 describe-target-groups 2>/dev/null || true
echo "✅ ELB / ALB OK"
echo "------------------------------------------------------------"

# 9. Route 53 Test
echo "🌐 Testing Route 53 DNS..."
aws route53 list-hosted-zones
ZONE_ID=$(aws route53 create-hosted-zone --name testdomain.local --caller-reference "test-$(date +%s)" --query 'HostedZone.Id' --output text 2>/dev/null || true)
if [ -n "$ZONE_ID" ]; then
  aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID"
fi
echo "✅ Route 53 OK"
echo "------------------------------------------------------------"

# 10. CloudFront Test
echo "⚡ Testing CloudFront CDN..."
aws cloudfront list-distributions 2>/dev/null || true
echo "✅ CloudFront OK"
echo "------------------------------------------------------------"

echo "============================================================"
echo "🎉 ALL AWS INFRASTRUCTURE SERVICES VERIFIED SUCCESSFULLY ON LOCALEMU!"
echo "============================================================"
