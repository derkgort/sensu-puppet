require 'spec_helper_acceptance'

describe 'sensugo_check', if: RSpec.configuration.sensugo_full do
  node = hosts_as('sensugo_backend')[0]
  before do
    if ! RSpec.configuration.sensugo_test_enterprise
      skip("Skipping enterprise tests")
    end
  end
  context 'default' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensugo::backend':
        license_source => '/root/sensugo_license.json',
      }
      sensugo_ldap_auth { 'openldap':
        ensure              => 'present',
        servers             => [
          {
            'host' => '127.0.0.1',
            'port' => 389,
          },
        ],
        server_binding      => {
          '127.0.0.1' => {
            'user_dn' => 'cn=binder,dc=acme,dc=org',
            'password' => 'P@ssw0rd!'
          }
        },
        server_group_search => {
          '127.0.0.1' => {
            'base_dn' => 'dc=acme,dc=org',
          }
        },
        server_user_search  => {
          '127.0.0.1' => {
            'base_dn' => 'dc=acme,dc=org',
          }
        },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid LDAP auth' do
      on node, 'sensuctl auth info openldap --format json' do
        data = JSON.parse(stdout)
        expect(data['servers'].size).to eq(1)
        expect(data['servers'][0]['host']).to eq('127.0.0.1')
        expect(data['servers'][0]['port']).to eq(389)
        expect(data['servers'][0]['insecure']).to eq(false)
        expect(data['servers'][0]['security']).to eq('tls')
        expect(data['servers'][0]['binding']).to eq({'user_dn' => 'cn=binder,dc=acme,dc=org', 'password' => 'P@ssw0rd!'})
        expect(data['servers'][0]['group_search']).to eq({'base_dn' => 'dc=acme,dc=org','attribute' => 'member','name_attribute' => 'cn','object_class' => 'groupOfNames'})
        expect(data['servers'][0]['user_search']).to eq({'base_dn' => 'dc=acme,dc=org','attribute' => 'uid','name_attribute' => 'cn','object_class' => 'person'})
      end
    end
  end

  context 'updates auth' do
    it 'should work without errors' do
      pp = <<-EOS
      class { '::sensugo::backend':
        license_source => '/root/sensugo_license.json',
      }
      sensugo_ldap_auth { 'openldap':
        ensure              => 'present',
        servers             => [
          {
            'host' => 'localhost',
            'port' => 636,
          },
        ],
        server_binding      => {
          'localhost' => {
            'user_dn' => 'cn=test,dc=acme,dc=org',
            'password' => 'password'
          }
        },
        server_group_search => {
          'localhost' => {
            'base_dn' => 'dc=acme,dc=org',
          }
        },
        server_user_search  => {
          'localhost' => {
            'base_dn' => 'dc=acme,dc=org',
          }
        },
      }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    it 'should have a valid ldap auth' do
      on node, 'sensuctl auth info openldap --format json' do
        data = JSON.parse(stdout)
        expect(data['servers'].size).to eq(1)
        expect(data['servers'][0]['host']).to eq('localhost')
        expect(data['servers'][0]['port']).to eq(636)
        expect(data['servers'][0]['insecure']).to eq(false)
        expect(data['servers'][0]['security']).to eq('tls')
        expect(data['servers'][0]['binding']).to eq({'user_dn' => 'cn=test,dc=acme,dc=org', 'password' => 'password'})
        expect(data['servers'][0]['group_search']).to eq({'base_dn' => 'dc=acme,dc=org','attribute' => 'member','name_attribute' => 'cn','object_class' => 'groupOfNames'})
        expect(data['servers'][0]['user_search']).to eq({'base_dn' => 'dc=acme,dc=org','attribute' => 'uid','name_attribute' => 'cn','object_class' => 'person'})
      end
    end
  end

  context 'ensure => absent' do
    it 'should remove without errors' do
      pp = <<-EOS
      include ::sensugo::backend
      sensugo_ldap_auth { 'openldap': ensure => 'absent' }
      EOS

      # Run it twice and test for idempotency
      apply_manifest_on(node, pp, :catch_failures => true)
      apply_manifest_on(node, pp, :catch_changes  => true)
    end

    describe command('sensuctl auth info openldap'), :node => node do
      its(:exit_status) { should_not eq 0 }
    end
  end
end

