#!/bin/bash
. /etc/profile
set -ex

. environment.sh

bash "$(dirname $0)/../../../infrastructure/infra-scripts/eni-attach-to-app.sh" $VoteSUp_app_stack_name
