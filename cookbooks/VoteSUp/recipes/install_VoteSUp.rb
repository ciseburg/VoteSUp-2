#
# Cookbook Name:: VoteSUp
# Recipe:: install_VoteSUp
#
# MIT License
# Copyright (c) 2016 
#

remote_directory '/VoteSUp' do
  source 'app'
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

directory '/VoteSUp/log' do
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

bash 'VoteSUp' do
  user 'root'
  flags '-ex'
  code <<-EOH
if /usr/local/bin/forever list | grep -q '^data:'; then
  /usr/local/bin/forever stopall
  sleep 1
fi
/usr/local/bin/forever /VoteSUp/node-app/app.js >> /VoteSUp/log/server.log 2>&1 &
EOH
end
