require 'base64'
# Get base64 encoded validation.pem from CHEF_VALIDATOR and save to /etc/chef/validation.pem
# Run knife bootstrap?

# Determine our target from env or use default
TARGET = ENV['TARGET'] || node['chef_bootstrap_self']['defaults']['TARGET']

METADATA_PARAMS = ['CHEF_RUN_LIST', 'CHEF_VALIDATION_BASE64', 'CHEF_SERVER', 'CHEF_VALIDATION_NAME', 'CHEF_ENVIRONMENT']

# If target is GCP, get metadata from the API and set defaults if it didn't exist
METADATA_PARAMS.each do |param|
  if TARGET == "GCP"
    result = `curl "http://metadata.google.internal/computeMetadata/v1/instance/attributes/#{param}" -H "Metadata-Flavor: Google"`
  end

  Chef::Log.info("Result from attribute request is: #{result}")

  node.set['chef_bootstrap_self']['config']["#{param}"] = result || node['chef_bootstrap_self']['defaults']["#{param}"]
end

# Create directories for chef configs and chef logs
DIRECTORIES = ['/etc/chef', '/var/log/chef']
DIRECTORIES.each do |dir|
  directory dir do
    action :create
  end
end

# Decode validation pem and save to file
VALIDATION = Base64.decode64(node['chef_bootstrap_self']['config']['CHEF_VALIDATION_BASE64'])

file '/etc/chef/validation.pem' do
  content VALIDATION
  action :create
end

# Create client.rb chef config
template "/etc/chef/client.rb" do
  variables ({
    CONFIG_CHEF_SERVER: node['chef_bootstrap_self']['config']['CHEF_SERVER'],
    CONFIG_CHEF_VALIDATION_NAME: node['chef_bootstrap_self']['config']['CHEF_VALIDATION_NAME'],
    CONFIG_HOSTNAME: node['hostname']
  })
  action :create
end

# Write out a JSON file for first chef-client run
# Should include:
# - run_list
# - environment

FIRSTBOOT = <<-JSON
{
  "run_list": "#{node['chef_bootstrap_self']['config']['CHEF_RUN_LIST']}",
  "chef_environment": "#{node['chef_bootstrap_self']['config']['CHEF_ENVIRONMENT']}"
}
JSON

file '/etc/chef/firstboot.json' do
  content FIRSTBOOT
  action :create
end

# Run chef-client (use chef-client cookbook?)
bash 'firstboot_chef_run' do
  code <<-EOH
    chef-client -j /etc/chef/firstboot.json
  EOH
end
