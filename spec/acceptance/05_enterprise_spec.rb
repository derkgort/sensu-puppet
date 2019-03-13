require 'spec_helper_acceptance'

describe 'sensugo::backend class', unless: RSpec.configuration.sensugo_cluster do
  node = hosts_as('sensugo_backend')[0]
  before do
    if ! RSpec.configuration.sensugo_test_enterprise
      skip("Skipping enterprise tests")
    end
  end
  context 'adds license file' do
    it 'should work without errors and be idempotent' do
      pp = <<-EOS
      class { '::sensugo::backend':
        license_source => '/root/sensugo_license.json',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe command('sensuctl license info'), :node => node do
      its(:exit_status) { should eq 0 }
    end
  end
end
