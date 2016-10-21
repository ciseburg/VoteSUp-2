#
# Cookbook Name:: VoteSUp
# Recipe:: nginx_config
#
# MIT License
# Copyright (c) 2016 
#

cookbook_file '/etc/nginx/sites-available/VoteSUp/node-app' do
  source 'nginx/ssl-VoteSUp-site.cfg'
  owner 'root'
  group 'root'
  mode '0644'
  action :create
end

cookbook_file '/tmp/generate-cert.sh' do
  source 'nginx/generate-cert.sh'
  owner 'root'
  group 'root'
  mode '0700'
  action :create
end

execute 'generate-cert' do
  cwd '/tmp'
  command '/tmp/generate-cert.sh VoteSUp' 
end

directory '/etc/nginx/ssl/' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file '/etc/nginx/ssl/nginx.crt' do
  source 'file:///tmp/VoteSUp.crt'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

remote_file '/etc/nginx/ssl/nginx.key' do
  source 'file:///tmp/VoteSUp.key'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

link '/etc/nginx/sites-enabled/000-default' do
  to '/etc/nginx/sites-available/VoteSUp/node-app'
end

service 'nginx' do
  action [ :start, :enable ]
end
