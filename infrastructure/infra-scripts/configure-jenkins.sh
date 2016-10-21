#!/usr/bin/env bash
set -e

echo "In configure-jenkins.sh"
script_dir="$(dirname "$0")"
bin_dir="$(dirname $0)/../infrastructue/infra-scripts"

echo The value of arg 0 = $0
echo The value of arg 1 = $1 
echo The value of arg script_dir = $script_dir

uuid=$(date +%s)

pipeline_store_stackname=$1

VPCStackName="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`VPCStackName`].OutputValue')"
IAMStackName="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`IAMStackName`].OutputValue')"
DDBStackName="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`DDBStackName`].OutputValue')"
ENIStackName="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ENIStackName`].OutputValue')"
MasterStackName="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`MasterStackName`].OutputValue')"
VoteSUp_s3_bucket=VoteSUp-"$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`VoteSUpS3Bucket`].OutputValue')"
VoteSUp_branch="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`Branch`].OutputValue')"
VoteSUp_ec2_key="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`KeyName`].OutputValue')"

#prod_dns_param="pmd.oneclickdeployment.com"

my_prod_dns_param="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ProdHostedZone`].OutputValue')"
prod_dns_param="$MasterStackName$my_prod_dns_param"
echo "The value of prod_dns_param is $prod_dns_param"

prod_dns="$(echo $prod_dns_param | sed 's/[.]$//')"

VoteSUp_hostname=$(echo $prod_dns | cut -f 1 -d . -s)
VoteSUp_domainname=$(echo $prod_dns | sed s/^$VoteSUp_hostname[.]//)

echo "VoteSUp_hostname is $VoteSUp_hostname"
echo "VoteSUp_domainname is $VoteSUp_domainname"

my_domainname="$VoteSUp_domainname."


if [ -z "$VoteSUp_hostname" -o -z "$VoteSUp_domainname" ]; then
    echo "Fatal: $prod_dns is an invalid hostname" >&2
    exit 1
fi

VoteSUp_zone_id=$(aws route53 list-hosted-zones --output=text --query "HostedZones[?Name==\`${VoteSUp_domainname}.\`].Id" | sed 's,^/hostedzone/,,')
if [ -z "$VoteSUp_zone_id" ]; then
    echo "Fatal: unable to find Route53 zone id for $VoteSUp_domainname." >&2
    exit 1
fi

echo "VoteSUp_zone_id is $VoteSUp_zone_id"

VoteSUp_vpc_stack_name="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`VPCStackName`].OutputValue')"
VoteSUp_iam_stack_name="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`IAMStackName`].OutputValue')"
VoteSUp_ddb_stack_name="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`DDBStackName`].OutputValue')"
VoteSUp_eni_stack_name="$(aws cloudformation describe-stacks --stack-name $pipeline_store_stackname --output text --query 'Stacks[0].Outputs[?OutputKey==`ENIStackName`].OutputValue')"
#VoteSUp_eni_stack_name="ENIStack$(echo $uuid)"
jenkins_custom_action_provider_name="Jenkins$(echo $uuid)"

temp_dir=$(mktemp -d /tmp/VoteSUp.XXXX)
config_dir="$(dirname $0)/../workflow/jenkins-jobs/xml"
config_tar_path="$MasterStackName/jenkins-job-configs-$uuid.tgz"

echo "The value of VPCStackName is $VPCStackName"
echo "The value of IAMStackName is $IAMStackName"
echo "The value of DDBStackName is $DDBStackName"
echo "The value of ENIStackName is $ENIStackName"
echo "The value of MasterStackName is $MasterStackName"
echo "The value of VoteSUp_s3_bucket is $VoteSUp_s3_bucket"
echo "The value of VoteSUp_branch is $VoteSUp_branch"
echo "The value of VoteSUp_domainname is $VoteSUp_domainname"
echo "The value of VoteSUp_ec2_key is $VoteSUp_ec2_key"
echo "The value of VoteSUp_zone_id is $VoteSUp_zone_id"
echo "The value of VoteSUp_iam_stack_name is $VoteSUp_iam_stack_name"
echo "The value of VoteSUp_ddb_stack_name is $VoteSUp_ddb_stack_name"
echo "The value of VoteSUp_eni_stack_name is $VoteSUp_eni_stack_name"
echo "The value of jenkins_custom_action_provider_name is $jenkins_custom_action_provider_name"
echo "The value of VoteSUp_eni_stack_name is $VoteSUp_eni_stack_name"
echo "The value of my_domainname is $my_domainname"

eni_subnet_id="$(aws cloudformation describe-stacks --stack-name $VoteSUp_vpc_stack_name --output text --query 'Stacks[0].Outputs[?OutputKey==`SubnetId`].OutputValue')"

echo "The value of eni_subnet_id is $eni_subnet_id"

cp -r $config_dir/* $temp_dir/
pushd $temp_dir > /dev/null
for f in */config.xml; do
    sed s/VoteSUpJenkins/$jenkins_custom_action_provider_name/ $f > $f.new && mv $f.new $f
done
sed s/S3BUCKET_PLACEHOLDER/$VoteSUp_s3_bucket/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/BRANCH_PLACEHOLDER/$VoteSUp_branch/ job-seed/config.xml > job-seed/config.xml.new && mv job-seed/config.xml.new job-seed/config.xml
sed s/VPC_PLACEHOLDER/$VoteSUp_vpc_stack_name/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/IAM_PLACEHOLDER/$VoteSUp_iam_stack_name/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/DDB_PLACEHOLDER/$VoteSUp_ddb_stack_name/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/ENI_PLACEHOLDER/$VoteSUp_eni_stack_name/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/KEY_PLACEHOLDER/$VoteSUp_ec2_key/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/HOSTNAME_PLACEHOLDER/$VoteSUp_hostname/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/DOMAINNAME_PLACEHOLDER/$VoteSUp_domainname/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/ZONE_ID_PLACEHOLDER/$VoteSUp_zone_id/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml
sed s/ACTION_PROVIDER_PLACEHOLDER/$jenkins_custom_action_provider_name/ VoteSUp-build/config.xml > VoteSUp-build/config.xml.new && mv VoteSUp-build/config.xml.new VoteSUp-build/config.xml

tar czf job-configs.tgz *
aws s3 cp job-configs.tgz s3://$VoteSUp_s3_bucket/$config_tar_path
popd > /dev/null
rm -rf $temp_dir

if ! aws s3 ls s3://$VoteSUp_s3_bucket/$config_tar_path; then
    echo "Fatal: Unable to upload Jenkins job configs to s3://$VoteSUp_s3_bucket/$config_tar_path" >&2
    exit 1
fi

aws cloudformation update-stack \
    --stack-name $pipeline_store_stackname \
    --use-previous-template \
    --capabilities="CAPABILITY_IAM" \
    --parameters ParameterKey=UUID,ParameterValue=$uuid \
        ParameterKey=VoteSUpS3Bucket,ParameterValue=$VoteSUp_s3_bucket \
        ParameterKey=Branch,ParameterValue=$VoteSUp_branch \
        ParameterKey=MasterStackName,ParameterValue=$MasterStackName \
        ParameterKey=JobConfigsTarball,ParameterValue=$config_tar_path \
        ParameterKey=Hostname,ParameterValue=$VoteSUp_hostname \
        ParameterKey=Domain,ParameterValue=$my_domainname \
        ParameterKey=MyBuildProvider,ParameterValue=$jenkins_custom_action_provider_name \
        ParameterKey=ProdHostedZone,ParameterValue=$prod_dns_param \
        ParameterKey=VPCStackName,ParameterValue=$VPCStackName \
        ParameterKey=IAMStackName,ParameterValue=$IAMStackName \
        ParameterKey=DDBStackName,ParameterValue=$DDBStackName \
        ParameterKey=ENIStackName,ParameterValue=$VoteSUp_eni_stack_name \
        ParameterKey=VoteSUpAppURL,ParameterValue=$prod_dns_param \
        ParameterKey=KeyName,ParameterValue=$VoteSUp_ec2_key
 
sleep 60

