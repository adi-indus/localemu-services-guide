# LocalEmu AWS Services Configuration & Integration Guide

A complete, step-by-step hands-on guide for configuring, testing, and integrating all core AWS infrastructure services (**EC2, S3, Lambda, DynamoDB, SQS, SNS, RDS, EKS, ELB/ALB, Route 53, VPC, CloudFront, Secrets Manager, SSM Parameter Store, IAM, API Gateway, CloudWatch**) locally using **LocalEmu**.

---

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Prerequisites & Activation](#quick-prerequisites--activation)
- [1. Amazon S3 (Simple Storage Service)](#1-amazon-s3-simple-storage-service)
- [2. AWS Lambda (Serverless Compute)](#2-aws-lambda-serverless-compute)
- [3. Amazon DynamoDB (NoSQL Database)](#3-amazon-dynamodb-nosql-database)
- [4. Amazon SQS (Simple Queue Service)](#4-amazon-sqs-simple-queue-service)
- [5. Amazon SNS (Simple Notification Service)](#5-amazon-sns-simple-notification-service)
- [6. Amazon EC2 (Elastic Compute Cloud)](#6-amazon-ec2-elastic-compute-cloud)
- [7. Amazon EKS (Elastic Kubernetes Service)](#7-amazon-eks-elastic-kubernetes-service)
- [8. Elastic Load Balancing (ALB / ELBv2)](#8-elastic-load-balancing-alb--elbv2)
- [9. Amazon Route 53 (DNS Domain Management)](#9-amazon-route-53-dns-domain-management)
- [10. Amazon VPC (Virtual Private Cloud & Networking)](#10-amazon-vpc-virtual-private-cloud--networking)
- [11. Amazon CloudFront (CDN)](#11-amazon-cloudfront-cdn)
- [12. AWS Secrets Manager & SSM Parameter Store](#12-aws-secrets-manager--ssm-parameter-store)
- [13. AWS IAM (Identity & Access Management)](#13-aws-iam-identity--access-management)
- [14. Amazon API Gateway](#14-amazon-api-gateway)
- [15. Amazon CloudWatch (Logs & Metrics)](#15-amazon-cloudwatch-logs--metrics)
- [16. Amazon RDS (Relational Database Service)](#16-amazon-rds-relational-database-service)

---

## 🔍 Overview

This guide provides tested, copy-pasteable CLI commands and SDK patterns for every major AWS service in **LocalEmu**. All commands use the `awsl` shorthand (or plain `aws` after running `lemu-activate`).

Endpoint target: `http://localhost:4566`  
Region: `us-east-1`  
Access Key / Secret: `test` / `test`

---

## ⚡ Quick Prerequisites & Activation

1. Ensure Docker Desktop or Colima is running.
2. Start LocalEmu and activate your terminal session:
   ```bash
   lemu-up
   lemu-activate
   ```

---

## 1. Amazon S3 (Simple Storage Service)

### A. CLI Management

```bash
# 1. Create a bucket
aws s3 mb s3://app-uploads-local

# 2. List buckets
aws s3 ls

# 3. Upload a file
echo "Hello from LocalEmu S3" > sample.txt
aws s3 cp sample.txt s3://app-uploads-local/documents/sample.txt

# 4. List bucket contents
aws s3 ls s3://app-uploads-local/documents/

# 5. Download a file
aws s3 cp s3://app-uploads-local/documents/sample.txt downloaded.txt
cat downloaded.txt

# 6. Configure CORS policy on bucket
cat << 'EOF' > cors.json
{
  "CORSRules": [
    {
      "AllowedHeaders": ["*"],
      "AllowedMethods": ["GET", "PUT", "POST", "DELETE"],
      "AllowedOrigins": ["*"],
      "ExposeHeaders": []
    }
  ]
}
EOF
aws s3api put-bucket-cors --bucket app-uploads-local --cors-configuration file://cors.json
```

### B. Node.js (AWS SDK v3) Example
> ⚠️ **Important:** Enable `forcePathStyle: true` for local S3 emulation.

```typescript
import { S3Client, PutObjectCommand, GetObjectCommand } from "@aws-sdk/client-s3";

const s3 = new S3Client({
  region: "us-east-1",
  endpoint: "http://localhost:4566",
  credentials: { accessKeyId: "test", secretAccessKey: "test" },
  forcePathStyle: true,
});

async function run() {
  await s3.send(new PutObjectCommand({
    Bucket: "app-uploads-local",
    Key: "test.txt",
    Body: "Hello S3!",
  }));
  console.log("File uploaded to local S3!");
}
```

---

## 2. AWS Lambda (Serverless Compute)

### A. CLI Management

```bash
# 1. Create a simple Python Lambda handler
cat << 'EOF' > index.py
def handler(event, context):
    name = event.get("name", "World")
    return {
        "statusCode": 200,
        "body": f"Hello {name} from LocalEmu Lambda!"
    }
EOF

# 2. Package into zip archive
zip function.zip index.py

# 3. Create IAM Role for Lambda
aws iam create-role \
  --role-name lambda-execution-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"lambda.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

# 4. Deploy Lambda Function
aws lambda create-function \
  --function-name greeting-service \
  --runtime python3.11 \
  --role arn:aws:iam::000000000000:role/lambda-execution-role \
  --handler index.handler \
  --zip-file fileb://function.zip

# 5. List Functions
aws lambda list-functions

# 6. Synchronous Invocation
aws lambda invoke \
  --function-name greeting-service \
  --payload '{"name": "Aditya"}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
# Output: {"statusCode": 200, "body": "Hello Aditya from LocalEmu Lambda!"}
```

---

## 3. Amazon DynamoDB (NoSQL Database)

### A. CLI Management

```bash
# 1. Create a DynamoDB Table
aws dynamodb create-table \
  --table-name UserProfiles \
  --attribute-definitions \
      AttributeName=UserId,AttributeType=S \
      AttributeName=CreatedAt,AttributeType=S \
  --key-schema \
      AttributeName=UserId,KeyType=HASH \
      AttributeName=CreatedAt,KeyType=RANGE \
  --billing-mode PAY_PER_REQUEST

# 2. List Tables
aws dynamodb list-tables

# 3. Put Item (Insert)
aws dynamodb put-item \
  --table-name UserProfiles \
  --item '{
    "UserId": {"S": "usr_1001"},
    "CreatedAt": {"S": "2026-07-30T12:00:00Z"},
    "FullName": {"S": "Aditya Shinde"},
    "Email": {"S": "aditya@example.com"},
    "Role": {"S": "ADMIN"}
  }'

# 4. Get Item (Read by Key)
aws dynamodb get-item \
  --table-name UserProfiles \
  --key '{
    "UserId": {"S": "usr_1001"},
    "CreatedAt": {"S": "2026-07-30T12:00:00Z"}
  }'

# 5. Scan Table
aws dynamodb scan --table-name UserProfiles
```

---

## 4. Amazon SQS (Simple Queue Service)

### A. CLI Management

```bash
# 1. Create a Standard Queue
aws sqs create-queue --queue-name order-processing-queue

# 2. Get Queue URL
QUEUE_URL=$(aws sqs get-queue-url --queue-name order-processing-queue --query 'QueueUrl' --output text)
echo "Queue URL: $QUEUE_URL"

# 3. Send Message
aws sqs send-message \
  --queue-url "$QUEUE_URL" \
  --message-body '{"order_id": "ORD-9921", "amount": 149.99, "status": "PENDING"}'

# 4. Receive Message
aws sqs receive-message \
  --queue-url "$QUEUE_URL" \
  --max-number-of-messages 1 \
  --wait-time-seconds 2

# 5. Delete Message (using ReceiptHandle)
# RECEIPT_HANDLE=$(...)
# aws sqs delete-message --queue-url "$QUEUE_URL" --receipt-handle "$RECEIPT_HANDLE"
```

---

## 5. Amazon SNS (Simple Notification Service)

### A. CLI Management & SQS Fanout Integration

```bash
# 1. Create SNS Topic
TOPIC_ARN=$(aws sns create-topic --name order-events --query 'TopicArn' --output text)
echo "Topic ARN: $TOPIC_ARN"

# 2. Create SQS Queue to subscribe to SNS
aws sqs create-queue --queue-name order-notifications
QUEUE_URL=$(aws sqs get-queue-url --queue-name order-notifications --query 'QueueUrl' --output text)
QUEUE_ARN=$(aws sqs get-queue-attributes --queue-url "$QUEUE_URL" --attribute-names QueueArn --query 'Attributes.QueueArn' --output text)

# 3. Subscribe SQS Queue to SNS Topic
aws sns subscribe \
  --topic-arn "$TOPIC_ARN" \
  --protocol sqs \
  --notification-endpoint "$QUEUE_ARN"

# 4. Publish Message to SNS Topic
aws sns publish \
  --topic-arn "$TOPIC_ARN" \
  --message '{"event": "ORDER_CREATED", "order_id": "ORD-9921"}'

# 5. Verify message received in SQS Queue
aws sqs receive-message --queue-url "$QUEUE_URL"
```

---

## 6. Amazon EC2 (Elastic Compute Cloud)

### A. CLI Management

```bash
# 1. Create a Key Pair
aws ec2 create-key-pair --key-name dev-keypair --query 'KeyMaterial' --output text > dev-keypair.pem
chmod 400 dev-keypair.pem

# 2. Create Security Group
SG_ID=$(aws ec2 create-security-group \
  --group-name web-sg \
  --description "Security group for web instances" \
  --query 'GroupId' --output text)

# 3. Authorize Inbound SSH and HTTP traffic
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 22 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id "$SG_ID" --protocol tcp --port 80 --cidr 0.0.0.0/0

# 4. Run (Launch) Instance
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-12345678 \
  --count 1 \
  --instance-type t3.micro \
  --key-name dev-keypair \
  --security-group-ids "$SG_ID" \
  --query 'Instances[0].InstanceId' --output text)

echo "Launched Instance ID: $INSTANCE_ID"

# 5. Describe Instances
aws ec2 describe-instances --instance-ids "$INSTANCE_ID"

# 6. Terminate Instance
aws ec2 terminate-instances --instance-ids "$INSTANCE_ID"
```

---

## 7. Amazon EKS (Elastic Kubernetes Service)

LocalEmu supports creating, describing, and deleting local EKS clusters as well as generating kubeconfig files to interact with Kubernetes APIs using `kubectl`.

### A. CLI Management

```bash
# 1. Create IAM Role for EKS Cluster
aws iam create-role \
  --role-name eks-cluster-role \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"eks.amazonaws.com"},"Action":"sts:AssumeRole"}]}'

# 2. Create EKS Cluster
aws eks create-cluster \
  --name local-dev-cluster \
  --role-arn arn:aws:iam::000000000000:role/eks-cluster-role \
  --resources-vpc-config subnetIds=subnet-123456,subnet-654321

# 3. List EKS Clusters
aws eks list-clusters

# 4. Describe EKS Cluster Status
aws eks describe-cluster --name local-dev-cluster

# 5. Create EKS Managed Node Group
aws eks create-nodegroup \
  --cluster-name local-dev-cluster \
  --nodegroup-name worker-nodes-1 \
  --subnets subnet-123456 \
  --node-role arn:aws:iam::000000000000:role/eks-node-role

# 6. Describe Node Group
aws eks describe-nodegroup --cluster-name local-dev-cluster --nodegroup-name worker-nodes-1

# 7. Update Kubeconfig to use with kubectl
aws eks update-kubeconfig --name local-dev-cluster --kubeconfig ~/.kube/config-localemu

# 8. Test kubectl connection
kubectl --kubeconfig ~/.kube/config-localemu get nodes

# 9. Clean up EKS resources
aws eks delete-nodegroup --cluster-name local-dev-cluster --nodegroup-name worker-nodes-1
aws eks delete-cluster --name local-dev-cluster
```

---

## 8. Elastic Load Balancing (ALB / ELBv2)

### A. CLI Management

```bash
# 1. Create Target Group
TG_ARN=$(aws elbv2 create-target-group \
  --name web-target-group \
  --protocol HTTP \
  --port 80 \
  --target-type instance \
  --vpc-id vpc-12345678 \
  --query 'TargetGroups[0].TargetGroupArn' --output text)

echo "Target Group ARN: $TG_ARN"

# 2. Register Instance Targets
aws elbv2 register-targets \
  --target-group-arn "$TG_ARN" \
  --targets Id=i-1234567890abcdef0 Id=i-0987654321fedcba0

# 3. Create Application Load Balancer (ALB)
ALB_ARN=$(aws elbv2 create-load-balancer \
  --name local-app-alb \
  --subnets subnet-123456 subnet-654321 \
  --security-groups sg-12345678 \
  --query 'LoadBalancers[0].LoadBalancerArn' --output text)

echo "ALB ARN: $ALB_ARN"

# 4. Create HTTP Listener
aws elbv2 create-listener \
  --load-balancer-arn "$ALB_ARN" \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn="$TG_ARN"

# 5. List Load Balancers & Target Groups
aws elbv2 describe-load-balancers
aws elbv2 describe-target-groups
```

---

## 9. Amazon Route 53 (DNS Domain Management)

### A. CLI Management

```bash
# 1. Create Hosted Zone
ZONE_ID=$(aws route53 create-hosted-zone \
  --name localdev.internal \
  --caller-reference "ref-$(date +%s)" \
  --query 'HostedZone.Id' --output text)

echo "Hosted Zone ID: $ZONE_ID"

# 2. List Hosted Zones
aws route53 list-hosted-zones

# 3. Create A Record pointing domain to local IP
cat << 'EOF' > record.json
{
  "Changes": [
    {
      "Action": "CREATE",
      "ResourceRecordSet": {
        "Name": "api.localdev.internal",
        "Type": "A",
        "TTL": 300,
        "ResourceRecords": [{"Value": "127.0.0.1"}]
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets \
  --hosted-zone-id "$ZONE_ID" \
  --change-batch file://record.json

# 4. List Record Sets
aws route53 list-resource-record-sets --hosted-zone-id "$ZONE_ID"
```

---

## 10. Amazon VPC (Virtual Private Cloud & Networking)

### A. CLI Management

```bash
# 1. Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block 10.0.0.0/16 --query 'Vpc.VpcId' --output text)
echo "VPC ID: $VPC_ID"

# 2. Create Subnets
SUBNET_PUBLIC=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
SUBNET_PRIVATE=$(aws ec2 create-subnet --vpc-id "$VPC_ID" --cidr-block 10.0.2.0/24 --availability-zone us-east-1b --query 'Subnet.SubnetId' --output text)

# 3. Create Internet Gateway & Attach to VPC
IGW_ID=$(aws ec2 create-internet-gateway --query 'InternetGateway.InternetGatewayId' --output text)
aws ec2 attach-internet-gateway --vpc-id "$VPC_ID" --internet-gateway-id "$IGW_ID"

# 4. Create Route Table & Route to Internet Gateway
ROUTE_TABLE_ID=$(aws ec2 create-route-table --vpc-id "$VPC_ID" --query 'RouteTable.RouteTableId' --output text)
aws ec2 create-route --route-table-id "$ROUTE_TABLE_ID" --destination-cidr-block 0.0.0.0/0 --gateway-id "$IGW_ID"

# 5. Associate Route Table with Public Subnet
aws ec2 associate-route-table --subnet-id "$SUBNET_PUBLIC" --route-table-id "$ROUTE_TABLE_ID"

echo "VPC Setup Complete!"
```

---

## 11. Amazon CloudFront (CDN)

### A. CLI Management

```bash
# 1. Create Distribution for S3 Origin
DIST_ID=$(aws cloudfront create-distribution \
  --origin-domain-name app-uploads-local.s3.amazonaws.com \
  --default-root-object index.html \
  --query 'Distribution.Id' --output text)

echo "CloudFront Distribution ID: $DIST_ID"

# 2. List Distributions
aws cloudfront list-distributions
```

---

## 12. AWS Secrets Manager & SSM Parameter Store

### A. Secrets Manager

```bash
# Create Secret
aws secretsmanager create-secret \
  --name local/database \
  --secret-string '{"username":"postgres","password":"SuperSecretPassword123!"}'

# Get Secret Value
aws secretsmanager get-secret-value --secret-id local/database
```

### B. SSM Parameter Store

```bash
# Put Parameter (String / SecureString)
aws ssm put-parameter \
  --name "/config/app/max_connections" \
  --type "String" \
  --value "100" \
  --overwrite

aws ssm put-parameter \
  --name "/config/app/jwt_secret" \
  --type "SecureString" \
  --value "my-super-secret-jwt-key-32-characters" \
  --overwrite

# Get Parameter
aws ssm get-parameter --name "/config/app/max_connections"
aws ssm get-parameter --name "/config/app/jwt_secret" --with-decryption
```

---

## 13. AWS IAM (Identity & Access Management)

```bash
# 1. Create IAM User
aws iam create-user --user-name dev-app-worker

# 2. Attach Policy
aws iam attach-user-policy \
  --user-name dev-app-worker \
  --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess

# 3. Create Access Key for User
aws iam create-access-key --user-name dev-app-worker
```

---

## 14. Amazon API Gateway

```bash
# 1. Create REST API
API_ID=$(aws apigateway create-rest-api --name "Local Service API" --query 'id' --output text)

# 2. Get Root Resource ID
ROOT_ID=$(aws apigateway get-resources --rest-api-id "$API_ID" --query 'items[0].id' --output text)

# 3. Create Resource /health
RESOURCE_ID=$(aws apigateway create-resource --rest-api-id "$API_ID" --parent-id "$ROOT_ID" --path-part "health" --query 'id' --output text)

# 4. Create GET Method
aws apigateway put-method --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" --http-method GET --authorization-type "NONE"

# 5. Create Mock Integration
aws apigateway put-integration --rest-api-id "$API_ID" --resource-id "$RESOURCE_ID" --http-method GET --type MOCK --request-templates '{"application/json":"{\"statusCode\": 200}"}'

# 6. Deploy API
aws apigateway create-deployment --rest-api-id "$API_ID" --stage-name dev

echo "API Gateway Endpoint: http://localhost:4566/restapis/$API_ID/dev/_user_request_/health"
```

---

## 15. Amazon CloudWatch (Logs & Metrics)

```bash
# 1. Create Log Group
aws logs create-log-group --log-group-name /aws/app/backend-service

# 2. Create Log Stream
aws logs create-log-stream --log-group-name /aws/app/backend-service --log-stream-name stream-001

# 3. Put Log Events
aws logs put-log-events \
  --log-group-name /aws/app/backend-service \
  --log-stream-name stream-001 \
  --log-events timestamp=$(date +%s000),message="Application booted successfully"

# 4. Get Log Events
aws logs get-log-events --log-group-name /aws/app/backend-service --log-stream-name stream-001
```

---

## 16. Amazon RDS (Relational Database Service)

```bash
# Describe DB Instances in LocalEmu
aws rds describe-db-instances

# Create DB Instance
aws rds create-db-instance \
  --db-instance-identifier local-postgres-db \
  --db-instance-class db.t3.micro \
  --engine postgres \
  --master-username postgres \
  --master-user-password Password123! \
  --allocated-storage 20
```

---

## 📄 License

MIT License. Open for community use and contributions.
