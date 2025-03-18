#!/bin/bash
set -e  # Exit script on error

AWS_REGION="us-east-1"
BASE_AMI="ami-0c55b159cbfafe1f0"  # Amazon Linux 2
INSTANCE_TYPE="t3.micro"
KEY_NAME="my-key-pair"

echo "Launching AMI Builder Instance..."
INSTANCE_ID=$(aws ec2 run-instances --image-id $BASE_AMI --instance-type $INSTANCE_TYPE --key-name $KEY_NAME \
  --security-groups sg-ec2 --query "Instances[0].InstanceId" --output text)

echo "Waiting for instance to be ready..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

echo "Installing dependencies..."
aws ssm send-command --instance-ids $INSTANCE_ID --document-name "AWS-RunShellScript" --parameters \
  'commands=[
    "sudo yum install -y nginx",
    "curl -sL https://rpm.nodesource.com/setup_18.x | sudo bash -",
    "sudo yum install -y nodejs",
    "mkdir -p /opt/payment-api",
    "echo -e \"const http = require(\'http\'); const server = http.createServer((req, res) => { res.writeHead(200, {\'Content-Type\': \'application/json\'}); res.end(JSON.stringify({ status: \'Payment Processed\', timestamp: new Date().toISOString() })); }); server.listen(3000);\" > /opt/payment-api/server.js",
    "nohup node /opt/payment-api/server.js &"
  ]'

echo "Creating AMI..."
AMI_ID=$(aws ec2 create-image --instance-id $INSTANCE_ID --name "payment-api-ami" --no-reboot --query "ImageId" --output text)

echo "Waiting for AMI to be available..."
aws ec2 wait image-available --image-ids $AMI_ID

echo "AMI Created: $AMI_ID"
echo $AMI_ID > ami-id.txt
