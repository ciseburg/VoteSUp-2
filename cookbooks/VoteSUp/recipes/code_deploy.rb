#
# Cookbook Name:: VoteSUp
# Recipe:: code_deploy
#
# MIT License
# Copyright (c) 2016 
#

directory '/tmp/codedeploy' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file '/tmp/codedeploy/install' do
  source "https://s3.amazonaws.com/aws-codedeploy-#{node[:region]}/latest/install"
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'codedeploy' do
  command '/tmp/codedeploy/install auto'
end

