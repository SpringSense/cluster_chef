POOL_NAME     = 'chef'
require File.dirname(__FILE__)+'/cloud_aspects'

# Example usage (starts the chef server, then logs in to it)
#   cloud-start -n server -c cloud/chef_clouds.rb
#   cloud-ssh   -n server -c cloud/chef_clouds.rb
# If you're on the west coast, to avoid 'ami not found' errors, first run
#   export EC2_URL=https://us-west-1.ec2.amazonaws.com

pool POOL_NAME do
  cloud :server do
    using :ec2
    settings = settings_for_node(POOL_NAME, :server)
    instances                   1..1
    is_generic_node             settings
    is_ebs_backed               settings
    is_chef_server              settings
    is_chef_client              settings
    mounts_ebs_volumes          settings
    is_nfs_server               settings
    is_spot_priced              settings
    user                        'ubuntu'
    security_group              POOL_NAME
    user_data                   bootstrap_chef_server_script(settings)
  end

  cloud :generic do
    using :ec2
    settings = settings_for_node(POOL_NAME, :client)
    instances                   1..1
    is_nfs_client               settings
    is_generic_node             settings
    is_ebs_backed               settings
    is_chef_client              settings
    is_spot_priced              settings
    user                        'ubuntu'
    disable_api_termination     false
    user_data_shell_script      = File.open(File.dirname(__FILE__)+'/../config/user_data_script-bootstrap_chef_client.sh').read
    user_data                   user_data_shell_script
  end
end
