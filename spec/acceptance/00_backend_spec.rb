require 'spec_helper_acceptance'

describe 'sensugo::backend class', unless: RSpec.configuration.sensugo_cluster do
  node = hosts_as('sensugo_backend')[0]
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu': }
      class { '::sensugo::backend':
        password     => 'supersecret',
        old_password => 'P@ssw0rd!',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
    describe package('sensu-go-agent'), :node => node do
      it { should_not be_installed }
    end
  end

  context 'backend and agent' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensu': }
      class { '::sensugo::backend':
        password     => 'supersecret',
        old_password => 'P@ssw0rd!',
      }
      class { '::sensugo::agent':
        backends => ['sensugo_backend:8081'],
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
    describe service('sensu-agent'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
  end

  context 'reset admin password' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensugo::backend':
        password     => 'P@ssw0rd!',
        old_password => 'supersecret',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe service('sensu-backend'), :node => node do
      it { should be_enabled }
      it { should be_running }
    end
  end
end
