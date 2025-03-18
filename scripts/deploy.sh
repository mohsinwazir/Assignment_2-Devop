#!/bin/bash
set -e

# Variables
VPC_CIDR="10.0.0.0/16"
AMI_ID=$(cat ami-id.txt)
INSTANCE_TYPE="t3.small"
KEY_NAME="payment-key"
REGION="us-east-1"

# Create VPC
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query 'Vpc.VpcId' --output text)
echo "VPC Created: $VPC_ID"

# Create Subnets
SUBNET_PUBLIC_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.1.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)
SUBNET_PRIVATE_A=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block 10.0.2.0/24 --availability-zone us-east-1a --query 'Subnet.SubnetId' --output text)

# Create Security Groups
SG_ALB=$(aws ec2 create-security-group --group-name sg-alb --description "ALB Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0

SG_EC2=$(aws ec2 create-security-group --group-name sg-payment-api --description "Payment API Security Group" --vpc-id $VPC_ID --query 'GroupId' --output text)
aws ec2 authorize-security-group-ingress --group-id $SG_EC2 --protocol tcp --port 80 --source-group $SG_ALB

# Launch EC2 Instances
INSTANCE_ID=$(aws ec2 run-instances --image-id $AMI_ID --instance-type $INSTANCE_TYPE --subnet-id $SUBNET_PRIVATE_A --security-group-ids $SG_EC2 --query 'Instances[0].InstanceId' --output text)
echo "EC2 Instance Created: $INSTANCE_ID"
