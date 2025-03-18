#!/bin/bash
set -e  # Exit script on error

AWS_REGION="us-east-1"
VPC_CIDR="10.0.0.0/16"
SUBNET_PUBLIC_A="10.0.1.0/24"
SUBNET_PUBLIC_B="10.0.3.0/24"
SUBNET_PRIVATE_A="10.0.2.0/24"
SUBNET_PRIVATE_B="10.0.4.0/24"

echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc --cidr-block $VPC_CIDR --query "Vpc.VpcId" --output text --region $AWS_REGION)
aws ec2 create-tags --resources $VPC_ID --tags Key=Application,Value=Payment-Processing

echo "Creating Subnets..."
SUBNET_PUB_A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_PUBLIC_A --availability-zone us-east-1a --query "Subnet.SubnetId" --output text)
SUBNET_PUB_B_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_PUBLIC_B --availability-zone us-east-1b --query "Subnet.SubnetId" --output text)
SUBNET_PRIV_A_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_PRIVATE_A --availability-zone us-east-1a --query "Subnet.SubnetId" --output text)
SUBNET_PRIV_B_ID=$(aws ec2 create-subnet --vpc-id $VPC_ID --cidr-block $SUBNET_PRIVATE_B --availability-zone us-east-1b --query "Subnet.SubnetId" --output text)

echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway --query "InternetGateway.InternetGatewayId" --output text)
aws ec2 attach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

echo "Creating Route Tables..."
RTB_PUBLIC_ID=$(aws ec2 create-route-table --vpc-id $VPC_ID --query "RouteTable.RouteTableId" --output text)
aws ec2 create-route --route-table-id $RTB_PUBLIC_ID --destination-cidr-block 0.0.0.0/0 --gateway-id $IGW_ID
aws ec2 associate-route-table --route-table-id $RTB_PUBLIC_ID --subnet-id $SUBNET_PUB_A_ID
aws ec2 associate-route-table --route-table-id $RTB_PUBLIC_ID --subnet-id $SUBNET_PUB_B_ID

echo "Creating Security Groups..."
SG_ALB=$(aws ec2 create-security-group --group-name sg-alb --description "ALB Security Group" --vpc-id $VPC_ID --query "GroupId" --output text)
SG_EC2=$(aws ec2 create-security-group --group-name sg-ec2 --description "EC2 Security Group" --vpc-id $VPC_ID --query "GroupId" --output text)

aws ec2 authorize-security-group-ingress --group-id $SG_ALB --protocol tcp --port 80 --cidr 0.0.0.0/0
aws ec2 authorize-security-group-ingress --group-id $SG_EC2 --protocol tcp --port 80 --source-group $SG_ALB
aws ec2 authorize-security-group-egress --group-id $SG_EC2 --protocol all --port -1 --cidr 0.0.0.0/0

echo "VPC and networking components created successfully!"
