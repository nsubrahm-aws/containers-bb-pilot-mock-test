#!/bin/bash

set -e

i_setup() {
  REGION_ID=$1
  ACCOUNT_ID=$2
  DB_RESOURCE_ID=$3

  JSON_DIR=../json
  cd ${JSON_DIR}

  sed -e 's/regionId/'"${REGION_ID}"'/g' -e 's/accountId/'"${ACCOUNT_ID}"'/g' -e 's/dbResourceId/'"${DB_RESOURCE_ID}"'/g' rds-policy.json > rds-policy.json.policy
  POLICY_ARN=`aws iam create-policy --policy-name rds-policy --policy-document file://rds-policy.json.policy --query 'Policy.Arn' --output text`
  echo "RDS Policy ARN: ${POLICY_ARN}"

  rm rds-policy.json.policy
}

if [[ $# -ne 3 ]] ; then
  echo 'USAGE: ./iam.sh regionId accountId resourceId'
  exit 1
fi

REGION_ID=$1
ACCOUNT_ID=$2
RESOURCE_ID=$3

i_setup ${REGION_ID} ${ACCOUNT_ID} ${RESOURCE_ID}