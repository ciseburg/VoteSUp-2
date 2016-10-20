#
# Cookbook Name:: VoteSUp
# Recipe:: prereqs
#
# MIT License
# Copyright (c) 2016 
#

if ['rhel', 'amazon'].include?(node['platform'])
  execute 'yum upgrade -y'
end
if ['ubuntu'].include?(node['platform'])
  execute 'aptitude update'
  execute 'aptitude upgrade -y'
end

include_recipe 'nginx'
include_recipe 'VoteSUp::nodejs'
include_recipe 'VoteSUp::yum_packages'

service 'nginx' do
  action [ :stop, :disable ]
end

execute 'touch /.VoteSUp-prereqs-installed'
