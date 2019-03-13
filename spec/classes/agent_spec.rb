require 'spec_helper'

describe 'sensugo::agent', :type => :class do
  on_supported_os({facterversion: '3.8.0'}).each do |os, facts|
    context "on #{os}" do
      let(:facts) { facts }
      describe 'with default values for all parameters' do
        it { should compile.with_all_deps }

        it { should contain_class('sensu')}
        it { should contain_class('sensugo::agent')}

        it {
          should contain_package('sensu-go-agent').with({
            'ensure'  => 'installed',
            'name'    => 'sensu-go-agent',
            'before'  => 'File[sensugo_etc_dir]',
            'require' => platforms[facts[:osfamily]][:package_require],
          })
        }

        agent_content = <<-END.gsub(/^\s+\|/, '')
          |---
          |backend-url:
          |- wss://localhost:8081
          |trusted-ca-file: "/etc/sensu/ssl/ca.crt"
        END

        it {
          should contain_file('sensugo_agent_config').with({
            'ensure'  => 'file',
            'path'    => '/etc/sensu/agent.yml',
            'content' => agent_content,
            'require' => 'Package[sensu-go-agent]',
            'notify'  => 'Service[sensu-agent]',
          })
        }

        it {
          should contain_service('sensu-agent').with({
            'ensure'    => 'running',
            'enable'    => true,
            'name'      => 'sensu-agent',
            'subscribe' => 'Class[Sensugo::Ssl]',
          })
        }
      end

      context 'with use_ssl => false' do
        let(:pre_condition) do
          "class { 'sensu': use_ssl => false }"
        end

        agent_content = <<-END.gsub(/^\s+\|/, '')
          |---
          |backend-url:
          |- ws://localhost:8081
        END

        it {
          should contain_file('sensugo_agent_config').with({
            'ensure'    => 'file',
            'path'      => '/etc/sensu/agent.yml',
            'content'   => agent_content,
            'show_diff' => 'true',
            'require'   => 'Package[sensu-go-agent]',
            'notify'    => 'Service[sensu-agent]',
          })
        }

        it { should contain_service('sensu-agent').without_notify }
      end

      context 'with show_diff => false' do
        let(:params) {{ :show_diff => false }}
        it { should contain_file('sensugo_agent_config').with_show_diff('false') }
      end

      context 'with manage_repo => false' do
        let(:pre_condition) do
          "class { 'sensu': manage_repo => false }"
        end
        it { should contain_package('sensu-go-agent').without_require }
      end

      # Test various backend values
      [
        ['ws://localhost:8081'],
        ['wss://localhost:8081'],
        ['localhost:8081'],
        ['127.0.0.1:8081'],
        ['ws://127.0.0.1:8081'],
        ['wss://127.0.0.1:8081'],
        ['test.example.com:8081'],
        ['ws://test.example.com:8081'],
        ['wss://test.example.com:8081'],
      ].each do |backends|
        context "with backends => #{backends}" do
          let(:params) { { :backends => backends } }

          it { should compile.with_all_deps }

          if backends[0] =~ /(ws|wss):\/\//
            backend = backends[0]
          else
            backend = "wss://#{backends[0]}"
          end

          agent_content = <<-END.gsub(/^\s+\|/, '')
            |---
            |backend-url:
            |- #{backend}
            |trusted-ca-file: "/etc/sensu/ssl/ca.crt"
          END

          it {
            should contain_file('sensugo_agent_config').with({
              'ensure'  => 'file',
              'path'    => '/etc/sensu/agent.yml',
              'content' => agent_content,
              'require' => 'Package[sensu-go-agent]',
              'notify'  => 'Service[sensu-agent]',
            })
          }
        end
      end
    end
  end
end

