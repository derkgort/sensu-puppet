require 'spec_helper'

describe 'sensugo::backend::resources', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      context 'with default values for all parameters' do
        it { should compile }
        it { should have_sensugo_namespace_resource_count(1) }
        it { should contain_sensugo_namespace('default').with_ensure('present') }
        it { should have_sensugo_user_resource_count(2) }
        it {
          should contain_sensugo_user('agent').with({
            'ensure'       => 'present',
            'disabled'     => 'false',
            'password'     => 'P@ssw0rd!',
            'old_password' => nil,
            'groups'       => ['system:agents'],
          })
        }
        it { should have_sensugo_cluster_role_resource_count(6) }
        it {
          should contain_sensugo_cluster_role('admin').with({
            'ensure' => 'present',
            'rules'  => [
              {
                'verbs'     => ['*'],
                'resources' => [
                  'assets',
                  'checks',
                  'entities',
                  'extensions',
                  'events',
                  'filters',
                  'handlers',
                  'hooks',
                  'mutators',
                  'silenced',
                  'roles',
                  'rolebindings',
                ],
                'resource_names' => nil,
              },
              {
                'verbs'     => ['get', 'list'],
                'resources' => ['namespaces'],
                'resource_names' => nil,
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role('cluster-admin').with({
            'ensure' => 'present',
            'rules'  => [
              {
                'verbs'     => ['*'],
                'resources' => ['*'],
                'resource_names' => nil,
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role('edit').with({
            'ensure' => 'present',
            'rules'  => [
              {
                'verbs'     => ['*'],
                'resources' => [
                  'assets',
                  'checks',
                  'entities',
                  'extensions',
                  'events',
                  'filters',
                  'handlers',
                  'hooks',
                  'mutators',
                  'silenced',
                ],
                'resource_names' => nil,
              },
              {
                'verbs'     => ['get', 'list'],
                'resources' => ['namespaces'],
                'resource_names' => nil,
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role('system:agent').with({
            'ensure' => 'present',
            'rules'  => [
              {
                'verbs'     => ['*'],
                'resources' => ['events'],
                'resource_names' => nil,
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role('system:user').with({
            'ensure' => 'present',
            'rules'  => [
              {
                'verbs'     => ['get', 'update'],
                'resources' => ['localselfuser'],
                'resource_names' => nil,
              },
              {
                'verbs'     => ['get', 'list'],
                'resources' => ['namespaces'],
                'resource_names' => nil,
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role('view').with({
            'ensure' => 'present',
            'rules'  => [
              {
                'verbs'     => ['get', 'list'],
                'resources' => [
                  'assets',
                  'checks',
                  'entities',
                  'extensions',
                  'events',
                  'filters',
                  'handlers',
                  'hooks',
                  'mutators',
                  'silenced',
                  'namespaces',
                ],
                'resource_names' => nil,
              },
            ],
          })
        }
        it { should have_sensugo_cluster_role_binding_resource_count(3) }
        it {
          should contain_sensugo_cluster_role_binding('cluster-admin').with({
            'ensure'   => 'present',
            'role_ref' => 'cluster-admin',
            'subjects' => [
              {
                'type' => 'Group',
                'name' => 'cluster-admins'
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role_binding('system:agent').with({
            'ensure'   => 'present',
            'role_ref' => 'system:agent',
            'subjects' => [
              {
                'type' => 'Group',
                'name' => 'system:agents'
              },
            ],
          })
        }
        it {
          should contain_sensugo_cluster_role_binding('system:user').with({
            'ensure'   => 'present',
            'role_ref' => 'system:user',
            'subjects' => [
              {
                'type' => 'Group',
                'name' => 'system:users'
              },
            ],
          })
        }
      end
    end
  end
end
