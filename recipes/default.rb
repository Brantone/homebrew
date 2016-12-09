#
# Author:: Joshua Timberman (<jtimberman@chef.io>)
# Author:: Graeme Mathieson (<mathie@woss.name>)
# Cookbook:: homebrew
# Recipe:: default
#
# Copyright:: 2011-2016, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

Chef::Resource.send(:include, Homebrew::Mixin)
Chef::Recipe.send(:include, Homebrew::Mixin)

homebrew_go = "#{Chef::Config[:file_cache_path]}/homebrew_go"

Chef::Log.debug("Homebrew owner is '#{homebrew_owner}'")

remote_file homebrew_go do
  source node['homebrew']['installer']['url']
  checksum node['homebrew']['installer']['checksum'] unless node['homebrew']['installer']['checksum'].nil?
  mode "755"
  not_if { ::File.exist? '/usr/local/bin/brew' }
end

begin
  template '/etc/sudoers.d/homebrew_sudo' do
    source 'homebrew_sudo.erb'
    variables (
      lazy {
        { :user => homebrew_owner, :hostname => node['hostname'],
          :commands => node['homebrew']['sudo']['commands'] }
      }
    )
    action :create
    mode '00644'
    user 'root'
    group 'wheel'
    not_if { (::File.exist? '/usr/local/bin/brew') || node['homebrew']['sudo']['commands'].empty? }
  end

  execute 'install homebrew' do
    command "#{homebrew_go} < /dev/null"
    environment lazy { { 'HOME' => ::Dir.home(homebrew_owner), 'USER' => homebrew_owner } }
    user homebrew_owner
    not_if { ::File.exist? '/usr/local/bin/brew' }
  end
ensure
  file '/etc/sudoers.d/homebrew_go' do
    action :delete
  end
end

if node['homebrew']['auto-update']
  package 'git' do
    not_if 'which git'
  end

  execute 'update homebrew from github' do
    environment lazy { { 'HOME' => ::Dir.home(homebrew_owner), 'USER' => homebrew_owner } }
    user homebrew_owner
    command '/usr/local/bin/brew update || true'
  end
end
