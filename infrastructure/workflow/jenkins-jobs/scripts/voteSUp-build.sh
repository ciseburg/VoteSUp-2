#!/bin/bash
. /etc/profile
set -ex

# setup environment.sh
if [ -n "$AWS_DEFAULT_REGION" ]; then
    echo "export AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION" > environment.sh
else
    echo "export AWS_DEFAULT_REGION=us-east-1" > environment.sh
fi
echo "export VoteSUp_s3_bucket=$VoteSUp_S3_BUCKET" >> environment.sh
echo "export VoteSUp_vpc_stack_name=$VoteSUp_VPC_STACK" >> environment.sh
echo "export VoteSUp_iam_stack_name=$VoteSUp_IAM_STACK" >> environment.sh
echo "export VoteSUp_ddb_stack_name=$VoteSUp_DDB_STACK" >> environment.sh
echo "export VoteSUp_eni_stack_name=$VoteSUp_ENI_STACK" >> environment.sh
echo "export VoteSUp_ec2_key=$VoteSUp_EC2_KEY" >> environment.sh
echo "export VoteSUp_hostname=$VoteSUp_HOSTNAME" >> environment.sh
echo "export VoteSUp_domainname=$VoteSUp_DOMAINNAME" >> environment.sh
echo "export VoteSUp_zone_id=$VoteSUp_ZONE_ID" >> environment.sh
echo "export VoteSUp_artifact=VoteSUp-$(date +%Y%m%d-%H%M%S).tar.gz" >> environment.sh
echo "export VoteSUp_custom_action_provider=$VoteSUp_ACTION_PROVIDER" >> environment.sh

. environment.sh

# since the workspace is maintained throughout the build,
# install dependencies now in a clear workspace
rm -rf node_modules dist
npm install

# build and upload artifact
gulp dist
aws s3 cp dist/archive.tar.gz s3://$VoteSUp_s3_bucket/$VoteSUp_artifact
