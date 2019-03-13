require 'spec_helper'
require 'puppet/type/sensugo_hook'

describe Puppet::Type.type(:sensugo_hook) do
  let(:default_config) do
    {
      name: 'test',
      command: 'test',
    }
  end
  let(:config) do
    default_config
  end
  let(:hook) do
    described_class.new(config)
  end

  it 'should add to catalog without raising an error' do
    catalog = Puppet::Resource::Catalog.new
    expect {
      catalog.add_resource hook
    }.to_not raise_error
  end

  it 'should require a name' do
    expect {
      described_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  defaults = {
    'namespace': 'default',
    'timeout': 60,
    'stdin': :false,
  }

  # String properties
  [
    :command,
    :namespace,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 'foo'
      expect(hook[property]).to eq('foo')
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(hook[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(hook[property]).to eq(default_config[property])
      end
    end
  end

  # String regex validated properties
  [
    :name,
  ].each do |property|
    it "should not accept invalid #{property}" do
      config[property] = 'foo bar'
      expect { hook }.to raise_error(Puppet::Error, /#{property.to_s} invalid/)
    end
  end

  # Array properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = ['foo', 'bar']
      expect(hook[property]).to eq(['foo', 'bar'])
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(hook[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(hook[property]).to eq(default_config[property])
      end
    end
  end

  # Integer properties
  [
    :timeout,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 30
      expect(hook[property]).to eq(30)
    end
    it "should accept valid #{property} as string" do
      config[property] = '30'
      expect(hook[property]).to eq(30)
    end
    it "should not accept invalid value for #{property}" do
      config[property] = 'foo'
      expect { hook }.to raise_error(Puppet::Error, /should be an Integer/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(hook[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(hook[property]).to eq(default_config[property])
      end
    end
  end

  # Boolean properties
  [
    :stdin
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = true
      expect(hook[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = false
      expect(hook[property]).to eq(:false)
    end
    it "should accept valid #{property}" do
      config[property] = 'true'
      expect(hook[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = 'false'
      expect(hook[property]).to eq(:false)
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { hook }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are true, false/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(hook[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(hook[property]).to eq(default_config[property])
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
      expect(hook[property]).to eq({'foo': 'bar'})
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { hook }.to raise_error(Puppet::Error, /should be a Hash/)
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(hook[property]).to eq(default)
      end
    else
      it "should not have a default for #{property}" do
        expect(hook[property]).to eq(default_config[property])
      end
    end
  end

  include_examples 'autorequires' do
    let(:res) { hook }
  end

  [
    :command,
  ].each do |property|
    it "should require property when ensure => present" do
      config.delete(property)
      config[:ensure] = :present
      expect { hook }.to raise_error(Puppet::Error, /You must provide a #{property}/)
    end
  end
end
