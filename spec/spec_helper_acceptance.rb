require 'beaker-rspec'
require 'beaker-puppet'
require 'beaker/module_install_helper'
require 'beaker/puppet_install_helper'

run_puppet_install_helper
install_module_dependencies
install_module
collection = ENV['BEAKER_PUPPET_COLLECTION'] || 'puppet5'
project_dir = File.absolute_path(File.join(File.dirname(__FILE__), '..'))

RSpec.configure do |c|
  c.add_setting :sensugo_full, default: false
  c.add_setting :sensugo_cluster, default: false
  c.add_setting :sensugo_enterprise_file, default: nil
  c.add_setting :sensugo_test_enterprise, default: false
  c.sensugo_full = (ENV['BEAKER_sensugo_full'] == 'yes' || ENV['BEAKER_sensugo_full'] == 'true')
  c.sensugo_cluster = (ENV['BEAKER_sensugo_cluster'] == 'yes' || ENV['BEAKER_sensugo_cluster'] == 'true')
  if ENV['sensugo_ENTERPRISE_FILE']
    enterprise_file = File.absolute_path(ENV['sensugo_ENTERPRISE_FILE'])
  else
    enterprise_file = File.join(project_dir, 'tests/sensugo_license.json')
  end
  if File.exists?(enterprise_file)
    scp_to(hosts_as('sensugo_backend'), enterprise_file, '/root/sensugo_license.json')
    c.sensugo_test_enterprise = true
  else
    c.sensugo_test_enterprise = false
  end

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install soft module dependencies
    on hosts, puppet('module', 'install', 'puppetlabs-apt', '--version', '">= 5.0.1 < 7.0.0"'), { :acceptable_exit_codes => [0,1] }
    if collection == 'puppet6'
      on hosts, puppet('module', 'install', 'puppetlabs-yumrepo_core', '--version', '">= 1.0.1 < 2.0.0"'), { :acceptable_exit_codes => [0,1] }
    end
    ssldir = File.join(project_dir, 'tests/ssl')
    scp_to(hosts, ssldir, '/etc/puppetlabs/puppet/ssl')
    hosts.each do |host|
      on host, "puppet config set --section main certname #{host.name}"
    end
  end
end
