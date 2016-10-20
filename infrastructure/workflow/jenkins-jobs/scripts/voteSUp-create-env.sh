#!/bin/bash
. /etc/profile
set -ex

bash "$(dirname $0)/../../../infrastructure/infra-scripts/cfn-create-app.sh"
