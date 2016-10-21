#!/bin/bash
. /etc/profile
set -ex

bash "$(dirname $0)/../../../infra-scripts/cfn-create-app.sh"
