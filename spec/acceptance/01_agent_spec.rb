require 'spec_helper_acceptance'

describe 'sensugo::agent class', unless: RSpec.configuration.sensugo_cluster do
  node = hosts_as('sensugo_agent')[0]
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu': }
      class { '::sensugo::agent':
        backends    => ['sensugo_backend:8081'],
        config_hash => {
          'name' => 'sensugo_agent',
        }
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-agent'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
