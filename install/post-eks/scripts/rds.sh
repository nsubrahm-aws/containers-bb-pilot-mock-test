#!/bin/bash

set -e

r_setup() {
  echo 'Updating RDS security group'
  EKS_VPC=$1
  RDS_VPC=$2
  RDS_DB_ID=$3
  GROUP_NAME=$4

  RDS_SG=`aws ec2 create-security-group --description "Mock test SG" --group-name ${GROUP_NAME} --vpc-id ${RDS_VPC} --query 'GroupId' --output text`
  
  # NAT_IPS=`aws cloudformation describe-stack-resources --stack-name $STACK_NAME | jq -r '.StackResources[] | select((.ResourceType=="AWS::EC2::EIP") and (.LogicalResourceId == "NATIP")) | .PhysicalResourceId'`
  # for n in "${NAT_IPS[@]}"
  # do
  #   aws ec2 authorize-security-group-ingress --group-id ${RDS_SG} --protocol tcp --port 3306 --cidr ${n}/32
  # done

  INSTANCE_IP=`aws ec2 describe-instances --filters "Name=tag:Name,Values=mock-ng-db-Node" --query Reservations[0].Instances[0].PublicIpAddress --output text`
  aws ec2 authorize-security-group-ingress --group-id ${RDS_SG} --protocol tcp --port 3306 --cidr ${INSTANCE_IP}/32
  aws rds modify-db-instance --db-instance-identifier ${RDS_DB_ID} --vpc-security-group-ids ${RDS_SG} --query 'DBInstance.DBInstanceIdentifier' --output text

  echo "${RDS_SG} in RDS VPC ${RDS_VPC} updated to allow MySQL traffic from EKS VPC ${EKS_VPC} NAT gateway"
}

if [[ $# -ne 3 ]] ; then
  echo 'USAGE: ./rds.sh eksVpc rdsVpc rdsDbId'
  exit 1
fi

EKS_VPC=$1
RDS_VPC=$2
RDS_DB_ID=$3
GROUP_NAME="mock-sg"

r_setup ${EKS_VPC} ${RDS_VPC} ${RDS_DB_ID} ${GROUP_NAME}