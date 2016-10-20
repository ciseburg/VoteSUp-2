#
# Cookbook Name:: VoteSUp
# Recipe:: default
#
# MIT License
# Copyright (c) 2016 
#

include_recipe 'VoteSUp::nginx_config'
# include_recipe 'VoteSUp::ssl_nginx_config'

include_recipe 'VoteSUp::install_VoteSUp'
