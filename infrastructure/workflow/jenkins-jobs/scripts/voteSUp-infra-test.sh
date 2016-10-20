#!/bin/bash
. /etc/profile
set -ex

. ./environment.sh

gem install rspec aws-sdk
pushd infrastructure/test-infra
export VoteSUp_security_group="$(aws cloudformation describe-stack-resources --region us-east-1 --stack-name $VoteSUp_app_stack_name  --query StackResources[?LogicalResourceId==\`InstanceSecurityGroup\`].PhysicalResourceId --output text)"
rspec
popd
