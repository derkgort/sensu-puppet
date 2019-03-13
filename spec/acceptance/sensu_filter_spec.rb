require 'spec_helper_acceptance'

describe 'sensugo_filter', if: RSpec.configuration.sensugo_full do
  node = hosts_as('sensugo_backend')[0]
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensugo::backend
      sensugo_filter { 'test':
        action         => 'allow',
        expressions    => ["event.Entity.Environment == 'production'"],
        runtime_assets => ['test'],
        labels         => { 'foo' => 'baz' },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid filter' do
      on node, 'sensuctl filter info test --format json' do
        data = JSON.parse(stdout)
        expect(data['action']).to eq('allow')
        expect(data['expressions']).to eq(["event.Entity.Environment == 'production'"])
        expect(data['runtime_assets']).to eq(['test'])
        expect(data['metadata']['labels']['foo']).to eq('baz')
      end
    end
  end

  context 'update filter' do
    it 'should work without errors' do
      pp = <<-EOS
      include ::sensugo::backend
      sensugo_filter { 'test':
        action     => 'allow',
        expressions => ["event.Entity.Environment == 'test'"],
        runtime_assets => ['test2'],
        labels         => { 'foo' => 'bar' },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid filter with updated propery' do
      on node, 'sensuctl filter info test --format json' do
        data = JSON.parse(stdout)
        expect(data['expressions']).to eq(["event.Entity.Environment == 'test'"])
        expect(data['runtime_assets']).to eq(['test2'])
        expect(data['metadata']['labels']['foo']).to eq('bar')
      end
    end
  end

  context 'ensure => absent' do
    it 'should remove without errors' do
      pp = <<-EOS
      include ::sensugo::backend
      sensugo_filter { 'test': ensure => 'absent' }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe command('sensuctl filter info test'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end

