require 'spec_helper'
require 'puppet/type/sensugo_handler'

describe Puppet::Type.type(:sensugo_handler) do
  let(:default_config) do
    {
      name: 'test',
      type: 'pipe',
      command: 'test',
      socket_host: '127.0.0.1',
      socket_port: 9000,
    }
  end
  let(:config) do
    default_config
  end
  let(:handler) do
    described_class.new(config)
  end

  it 'should add to catalog without raising an error' do
    catalog = Puppet::Resource::Catalog.new
    expect {
      catalog.add_resource handler
    }.to_not raise_error
  end

  it 'should require a name' do
    expect {
      described_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should accept type' do
    handler[:type] = 'tcp'
    expect(handler[:type]).to eq(:tcp)
  end

  it 'should not accept invalid type' do
    expect {
      handler[:type] = 'foo'
    }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are pipe, tcp, udp, set./)
  end

  defaults = {
    'namespace': 'default',
  }

  # String properties
  [
    :mutator,
    :command,
    :namespace,
    :socket_host,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 'foo'
      expect(handler[property]).to eq('foo')
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(handler[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(handler[property]).to eq(default_config[property])
      end
    end
  end

  # String regex validated properties
  [
    :name,
  ].each do |property|
    it "should not accept invalid #{property}" do
      config[property] = 'foo bar'
      expect { handler }.to raise_error(Puppet::Error, /#{property.to_s} invalid/)
    end
  end

  # Array properties
  [
    :filters,
    :env_vars,
    :handlers,
    :runtime_assets,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = ['foo', 'bar']
      expect(handler[property]).to eq(['foo', 'bar'])
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(handler[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(handler[property]).to eq(default_config[property])
      end
    end
  end

  # Integer properties
  [
    :timeout,
    :socket_port,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 30
      expect(handler[property]).to eq(30)
    end
    it "should accept valid #{property} as string" do
      config[property] = '30'
      expect(handler[property]).to eq(30)
    end
    it "should not accept invalid value for #{property}" do
      config[property] = 'foo'
      expect { handler }.to raise_error(Puppet::Error, /should be an Integer/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(handler[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(handler[property]).to eq(default_config[property])
      end
    end
  end

  # Boolean properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = true
      expect(handler[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = false
      expect(handler[property]).to eq(:false)
    end
    it "should accept valid #{property}" do
      config[property] = 'true'
      expect(handler[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = 'false'
      expect(handler[property]).to eq(:false)
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { handler }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are true, false/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(handler[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(handler[property]).to eq(default_config[property])
      end
    end
  end

  # Hash properties
  [
    :labels,
    :annotations,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = { 'foo': 'bar' }
      expect(handler[property]).to eq({'foo': 'bar'})
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { handler }.to raise_error(Puppet::Error, /should be a Hash/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(handler[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(handler[property]).to eq(default_config[property])
      end
    end
  end

  describe 'timeout' do
    it 'should have default for tcp type' do
      config[:type] = 'tcp'
      config.delete(:timeout)
      expect(handler[:timeout]).to eq(60)
    end
    it 'should not have default without tcp type' do
      config[:type] = 'pipe'
      expect(handler[:timeout]).to be_nil
    end
  end

  include_examples 'autorequires' do
    let(:res) { handler }
  end

  it 'should autorequire sensugo_filter' do
    filter = Puppet::Type.type(:sensugo_filter).new(:name => 'test', :action => 'allow', :expressions => ['event.Check.Occurrences == 1'])
    catalog = Puppet::Resource::Catalog.new
    config[:filters] = ['test']
    catalog.add_resource handler
    catalog.add_resource filter
    rel = handler.autorequire[0]
    expect(rel.source.ref).to eq(filter.ref)
    expect(rel.target.ref).to eq(handler.ref)
  end

  it 'should autorequire sensugo_mutator' do
    mutator = Puppet::Type.type(:sensugo_mutator).new(:name => 'test', :command => 'test')
    catalog = Puppet::Resource::Catalog.new
    config[:mutator] = 'test'
    catalog.add_resource handler
    catalog.add_resource mutator
    rel = handler.autorequire[0]
    expect(rel.source.ref).to eq(mutator.ref)
    expect(rel.target.ref).to eq(handler.ref)
  end

  it 'should autorequire sensugo_handler' do
    h = Puppet::Type.type(:sensugo_handler).new(:name => 'test2', :type => 'pipe', :command => 'test')
    catalog = Puppet::Resource::Catalog.new
    config[:handlers] = ['test2']
    catalog.add_resource handler
    catalog.add_resource h
    rel = handler.autorequire[0]
    expect(rel.source.ref).to eq(h.ref)
    expect(rel.target.ref).to eq(handler.ref)
  end

  it 'should autorequire sensugo_asset' do
    asset = Puppet::Type.type(:sensugo_asset).new(:name => 'test', :url => 'http://example.com/asset/example.tar', :sha512 => '4f926bf4328fbad2b9cac873d117f771914f4b837c9c85584c38ccf55a3ef3c2e8d154812246e5dda4a87450576b2c58ad9ab40c9e2edc31b288d066b195b21b')
    catalog = Puppet::Resource::Catalog.new
    config[:runtime_assets] = ['test']
    catalog.add_resource handler
    catalog.add_resource asset
    rel = handler.autorequire[0]
    expect(rel.source.ref).to eq(asset.ref)
    expect(rel.target.ref).to eq(handler.ref)
  end

  [
    :type,
  ].each do |property|
    it "should require property when ensure => present" do
      config.delete(property)
      config[:ensure] = :present
      expect { handler }.to raise_error(Puppet::Error, /You must provide a #{property}/)
    end
  end

  it 'should require command for type pipe' do
    config.delete(:command)
    expect { handler }.to raise_error(Puppet::Error, /command must be defined for type pipe/)
  end

  it 'should require socket_host and socket_port' do
    config.delete(:socket_port)
    expect { handler }.to raise_error(Puppet::Error, /socket_port is required if socket_host is set/)
  end
  it 'should require socket_host and socket_port' do
    config.delete(:socket_host)
    expect { handler }.to raise_error(Puppet::Error, /socket_host is required if socket_port is set/)
  end
  it 'should require socket properties for tcp type' do
    config.delete(:socket_host)
    config.delete(:socket_port)
    config[:type] = :tcp
    expect { handler }.to raise_error(Puppet::Error, /socket_host and socket_port are required for type tcp or type udp/)
  end
  it 'should require socket properties for udp type' do
    config.delete(:socket_host)
    config.delete(:socket_port)
    config[:type] = :udp
    expect { handler }.to raise_error(Puppet::Error, /socket_host and socket_port are required for type tcp or type udp/)
  end
  it 'should require handlers for type set' do
    config[:type] = 'set'
    config.delete(:handlers)
    expect { handler }.to raise_error(Puppet::Error, /handlers must be defined for type set/)
  end
end
