echo "Launching EC2 instances..."
INSTANCE_1=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.small --subnet-id $SUBNET_PRIV_A_ID --security-group-ids $SG_EC2 --query "Instances[0].InstanceId" --output text)
INSTANCE_2=$(aws ec2 run-instances --image-id $AMI_ID --instance-type t3.small --subnet-id $SUBNET_PRIV_B_ID --security-group-ids $SG_EC2 --query "Instances[0].InstanceId" --output text)

echo "Creating Application Load Balancer..."
ALB_ARN=$(aws elbv2 create-load-balancer --name payment-alb --subnets $SUBNET_PUB_A_ID $SUBNET_PUB_B_ID --security-groups $SG_ALB --query "LoadBalancers[0].LoadBalancerArn" --output text)

echo "Creating Target Group..."
TG_ARN=$(aws elbv2 create-target-group --name payment-target-group --protocol HTTP --port 80 --vpc-id $VPC_ID --query "TargetGroups[0].TargetGroupArn" --output text)

aws elbv2 register-targets --target-group-arn $TG_ARN --targets Id=$INSTANCE_1 Id=$INSTANCE_2

echo "Creating ALB Listener..."
aws elbv2 create-listener --load-balancer-arn $ALB_ARN --protocol HTTP --port 80 --default-actions Type=forward,TargetGroupArn=$TG_ARN

echo "Deployment complete!"
