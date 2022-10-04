# Mock test guide

- [Mock test guide](#mock-test-guide)
  - [Set-up Cloud9 instance](#set-up-cloud9-instance)
  - [Configure AWS CLI](#configure-aws-cli)
  - [Install tools](#install-tools)
  - [Initialize](#initialize)
  - [Amazon RDS](#amazon-rds)
    - [Launch database](#launch-database)
    - [Run DDL](#run-ddl)
    - [Set-up IAM policy](#set-up-iam-policy)
  - [Post EKS launch set-up](#post-eks-launch-set-up)
  - [Build container images](#build-container-images)
  - [Deploy](#deploy)

## Set-up Cloud9 instance

1. Launch a Cloud9 workspace as described [here](../docs/c9.md).

## Configure AWS CLI

1. Log in back to your dashboard using the URL provided for the event.
2. Using `aws configure` to configure region as `ap-south-1` and `json` as output format.

## Install tools

```bash
# Install jq 1.6
wget -q https://github.com/stedolan/jq/releases/download/jq-1.6/jq-linux64 -O jq
chmod +x jq
sudo mv jq /usr/local/bin/jq
# Install kubectl
sudo curl --silent --location -o /usr/local/bin/kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.21.5/2022-01-21/bin/linux/amd64/kubectl
sudo chmod +x /usr/local/bin/kubectl
# Install eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv -v /tmp/eksctl /usr/local/bin
# Install helm
curl --silent https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | /bin/bash -
```

## Initialize

1. Clone the repository with `git clone https://github.com/nsubrahm-aws/containers-black-belt-pilot-mock-test`

2. Set-up environment variables and change to `scripts` folder.

```bash
export ACCOUNT_ID=$(aws sts get-caller-identity --output text --query Account)
export REGION_ID=$(curl -s 169.254.169.254/latest/dynamic/instance-identity/document | jq -r '.region')
export PROJECT_HOME=${PWD}/containers-black-belt-pilot-mock-test
export INSTALL_HOME=${PROJECT_HOME}/install
cd ${INSTALL_HOME}
```

## Amazon RDS

### Launch database

1. Run the following commands to launch a Amazon RDS MySQL database.

```bash
export RDS_DB_ID=demo
export MYSQL_MASTER_PASSWORD=Change.Passw0rd
cd db/scripts
./db.sh
```

### Run DDL

1. Run the following commands to create database tables in the `demo` database created in the previous step.

```bash
./ddl.sh
```

### Set-up IAM policy

1. Run the following commands to set-up IAM policy for RDS.

```bash
export DB_RESOURCE_ID=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DbiResourceId' --output text`
./iam.sh ${REGION_ID} ${ACCOUNT_ID} ${DB_RESOURCE_ID}
```

2. Come back to install folder.

```bash
cd ${INSTALL_HOME}
```

## Post EKS launch set-up

> The instructions in this section need to be followed only after the Amazon EKS cluster is launched. 

1. Run the following commands to set-up access between Amazon EKS cluster and Amazon RDS database.

```bash
EKS_CLUSTER=mock
EKS_VPC=`aws eks describe-cluster --name ${EKS_CLUSTER} --query 'cluster.resourcesVpcConfig.vpcId' --output text`
RDS_VPC=`aws rds describe-db-instances --db-instance-identifier ${RDS_DB_ID} --query 'DBInstances[0].DBSubnetGroup.VpcId' --output text`
cd post-eks/scripts
STACK_NAME=eksctl-${EKS_CLUSTER}-cluster
./rds.sh ${EKS_VPC} ${RDS_VPC} ${RDS_DB_ID}
```

2. Set-up load balancer.

```bash
./elb.sh ${ACCOUNT_ID} ${REGION_ID} ${EKS_CLUSTER}
```

3. Attach IAM policy ARN.

```bash
NS=demo
./policy.sh ${REGION_ID} ${ACCOUNT_ID} ${EKS_CLUSTER} ${NS}
```

## Build container images

```bash
cd ${PROJECT_HOME}/app/src
docker build -t mock/demo . && docker tag mock/demo:latest accountId.dkr.ecr.ap-south-1.amazonaws.com/mock/demo:latest && docker push accountId.dkr.ecr.ap-south-1.amazonaws.com/mock/demo:latest
```

## Deploy

```bash
cd ${PROJECT_HOME}/app/yaml
kubectl create ns demo
kubectl -n demo create -f config.yaml
kubectl -n demo create -f deploy.yaml
kubectl -n demo create -f svc.yaml
kubectl -n demo create -f ing.yaml
```