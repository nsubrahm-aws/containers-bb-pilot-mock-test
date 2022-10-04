#!/bin/bash

set -e

p_setup() {
  REGION_ID=$1 
  ACCOUNT_ID=$2
  EKS_CLUSTER=$3
  NS=$4

  eksctl utils associate-iam-oidc-provider \
    --region ${REGION_ID} \
    --cluster ${EKS_CLUSTER} \
    --approve

  echo "Creating ${NS}/sa/demo with IAM policies for RDS"
  eksctl create iamserviceaccount \
  --cluster=${EKS_CLUSTER} \
  --namespace=${NS} \
  --name=demo \
  --attach-policy-arn=arn:aws:iam::${ACCOUNT_ID}:policy/rds-policy  \
  --override-existing-serviceaccounts \
  --region ${REGION_ID} \
  --approve
}

if [[ $# -ne 4 ]] ; then
  echo 'USAGE: ./policy.sh regionId accountId eksCluster namespace'
  exit 1
fi

p_setup $1 $2 $3 $4
