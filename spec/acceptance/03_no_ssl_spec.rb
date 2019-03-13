require 'spec_helper_acceptance'

describe 'sensu without SSL', unless: RSpec.configuration.sensugo_cluster do
  backend = hosts_as('sensugo_backend')[0]
  agent = hosts_as('sensugo_agent')[0]
  context 'backend' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu':
        use_ssl => false,
      }
      class { '::sensugo::backend':
        password     => 'P@ssw0rd!',
        old_password => 'supersecret',
      }
      sensugo_entity { 'sensugo_agent':
        ensure => 'absent',
      }
      EOS

      # Ensure agent entity doesn't get re-added
      on agent, 'puppet resource service sensu-agent ensure=stopped'
      apply_manifest_on(backend, pp, :catch_failures => true)
      apply_manifest_on(backend, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => backend do
      it { should be_enabled }
      it { should be_running }
    end

    describe command('sensuctl entity list'), :node => backend do
      its(:exit_status) { should eq 0 }
    end
  end

  context 'agent' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu':
        use_ssl => false,
      }
      class { '::sensugo::agent':
        backends    => ['sensugo_backend:8081'],
        config_hash => {
          'name' => 'sensugo_agent',
        }
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(agent, pp, :catch_failures => true)
      apply_manifest_on(agent, pp, :catch_changes  => true)
    end

    describe service('sensu-agent'), :node => agent do
      it { should be_enabled }
      it { should be_running }
    end

    describe command('sensuctl entity info sensugo_agent'), :node => backend do
      its(:exit_status) { should eq 0 }
    end
  end
end
