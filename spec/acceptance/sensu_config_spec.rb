require 'spec_helper_acceptance'

describe 'sensugo_config', if: RSpec.configuration.sensugo_full do
  node = hosts_as('sensugo_backend')[0]
  context 'with updates' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensugo::backend
      sensugo_config { 'format':
        value => 'json',
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid config' do
      on node, 'sensuctl config view --format json' do
        data = JSON.parse(stdout)
        expect(data['format']).to eq('json')
      end
    end
  end

  context 'ensure => absent' do
    it 'should result in error as unsupported' do
      pp = <<-EOS
      include ::sensugo::backend
      sensugo_config { 'format': ensure => 'absent' }
      EOS

      apply_manifest_on(node, pp, :expect_failures => true)
    end
  end
end

