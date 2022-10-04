#!/bin/bash

set -e

e_setup() {
  ACCOUNT_ID=$1  
  REGION_ID=$2
  EKS_CLUSTER=$3

  eksctl utils associate-iam-oidc-provider \
    --region ${REGION_ID} \
    --cluster ${EKS_CLUSTER} \
    --approve

  curl --silent -o iam-policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.3/docs/install/iam_policy.json

  POLICY_ARN=`aws iam create-policy \
    --policy-name AWSLoadBalancerControllerIAMPolicy \
    --policy-document file://iam-policy.json \
    --query 'Policy.Arn' --output text`
  echo "AWS LoadBalancer Controller Policy ARN: ${POLICY_ARN}"

  eksctl create iamserviceaccount \
    --cluster=${EKS_CLUSTER} \
    --namespace=kube-system \
    --name=aws-load-balancer-controller \
    --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/AWSLoadBalancerControllerIAMPolicy \
    --override-existing-serviceaccounts \
    --region ${REGION_ID} \
    --approve

  helm repo add eks https://aws.github.io/eks-charts
  helm install aws-load-balancer-controller eks/aws-load-balancer-controller \
    -n kube-system \
    --set clusterName=${EKS_CLUSTER} \
    --set serviceAccount.create=false \
    --set serviceAccount.name=aws-load-balancer-controller

  rm iam-policy.json
}

if [[ $# -ne 3 ]] ; then
  echo 'USAGE: ./elb.sh accountId regionId eksCluster'
  exit 1
fi

e_setup $1 $2 $3
