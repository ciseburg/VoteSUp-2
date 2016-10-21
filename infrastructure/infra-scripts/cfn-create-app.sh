#!/usr/bin/env bash
set -e

script_dir="$(dirname "$0")"
ENVIRONMENT_FILE="$script_dir/../../environment.sh"
if [ ! -f "$ENVIRONMENT_FILE" ]; then
    echo "Fatal: environment file $ENVIRONMENT_FILE does not exist!" 2>&1
    exit 1
fi

. $ENVIRONMENT_FILE

if [ -n "$1" ]; then
    VoteSUp_artifact="$1"
fi

if [ -z "$VoteSUp_artifact" ]; then
    echo "Fatal: \$VoteSUp_artifact not specified" >&2
    exit 1
fi

app_subnet_id="$(aws cloudformation describe-stacks --stack-name $VoteSUp_vpc_stack_name --output text --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue')"
vpc="$(aws cloudformation describe-stacks --stack-name $VoteSUp_vpc_stack_name --output text --query 'Stacks[0].Outputs[?OutputKey==`VPC`].OutputValue')"
app_instance_profile="$(aws cloudformation describe-stacks --stack-name $VoteSUp_iam_stack_name --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceProfile`].OutputValue')"
app_instance_role="$(aws cloudformation describe-stacks --stack-name $VoteSUp_iam_stack_name --output text --query 'Stacks[0].Outputs[?OutputKey==`InstanceRole`].OutputValue')"
app_ddb_table="$(aws cloudformation describe-stacks --stack-name $VoteSUp_ddb_stack_name --output text --query 'Stacks[0].Outputs[?OutputKey==`TableName`].OutputValue')"
app_custom_action_provider_name="VoteSUpJnkns$(date +%s)"

VoteSUp_app_stack_name="$VoteSUp_hostname-$(basename $VoteSUp_artifact .tar.gz)"
aws cloudformation create-stack \
    --disable-rollback \
    --stack-name $VoteSUp_app_stack_name \
    --template-body file://./infrastructure/workflow/cloudformation/VoteSUp-app.json \
    --parameters ParameterKey=Ec2Key,ParameterValue=$VoteSUp_ec2_key \
        ParameterKey=SubnetId,ParameterValue=$app_subnet_id \
        ParameterKey=VPC,ParameterValue=$vpc \
        ParameterKey=InstanceProfile,ParameterValue=$app_instance_profile \
        ParameterKey=CfnInitRole,ParameterValue=$app_instance_role \
        ParameterKey=S3Bucket,ParameterValue=$VoteSUp_s3_bucket \
        ParameterKey=ArtifactPath,ParameterValue=$VoteSUp_artifact \
        ParameterKey=DynamoDbTable,ParameterValue=$app_ddb_table \
    --tags Key=BuiltBy,Value=$VoteSUp_custom_action_provider

app_stack_status="$(bash $script_dir/cfn-wait-for-stack.sh $VoteSUp_app_stack_name)"
if [ $? -ne 0 ]; then
    echo "Fatal: Jenkins stack $VoteSUp_app_stack_name ($app_stack_status) failed to create properly" >&2
    exit 1
fi

echo "export VoteSUp_app_stack_name=$VoteSUp_app_stack_name" >> "$ENVIRONMENT_FILE"
