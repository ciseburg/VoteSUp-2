#!/bin/bash
. /etc/profile
set -ex

cd node-app
npm install
gulp lint
