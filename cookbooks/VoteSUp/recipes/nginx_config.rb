#
# Cookbook Name:: VoteSUp
# Recipe:: nginx_config
#
# MIT License
# Copyright (c) 2016 
#

cookbook_file '/etc/nginx/sites-available/VoteSUp' do
  source 'nginx/VoteSUp-site.cfg'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

link '/etc/nginx/sites-enabled/000-default' do
  to '/etc/nginx/sites-available/VoteSUp'
end

service 'nginx' do
  action [ :start, :enable ]
end
