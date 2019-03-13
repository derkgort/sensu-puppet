require 'spec_helper'
require 'puppet/type/sensugo_config'

describe Puppet::Type.type(:sensugo_config) do
  let(:default_config) do
    {
      name: 'format',
      value: 'json',
    }
  end
  let(:config) do
    default_config
  end
  let(:sensugo_config) do
    described_class.new(config)
  end

  it 'should add to catalog without raising an error' do
    catalog = Puppet::Resource::Catalog.new
    expect {
      catalog.add_resource sensugo_config
    }.to_not raise_error
  end

  it 'should require a name' do
    expect {
      described_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  it 'should not accept ensure => absent' do
    config[:ensure] = 'absent'
    expect { sensugo_config[:ensure] = 'absent' }.to raise_error(Puppet::Error, /ensure does not support absent/)
  end

  defaults = {}

  # String properties
  [
    :value,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 'foo'
      expect(sensugo_config[property]).to eq('foo')
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(sensugo_config[property]).to eq(default)
      end
    end
  end

  # String regex validated properties
  [
    :name,
  ].each do |property|
    it "should not accept invalid #{property}" do
      config[property] = 'foo bar'
      expect { sensugo_config }.to raise_error(Puppet::Error, /#{property.to_s} invalid/)
    end
  end

  # Array properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = ['foo', 'bar']
      expect(sensugo_config[property]).to eq(['foo', 'bar'])
    end
  end

  # Integer properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 30
      expect(sensugo_config[property]).to eq(30)
    end
    it "should accept valid #{property} as string" do
      config[property] = '30'
      expect(sensugo_config[property]).to eq(30)
    end
    it "should not accept invalid value for #{property}" do
      config[property] = 'foo'
      expect { sensugo_config }.to raise_error(Puppet::Error, /should be an Integer/)
    end
  end

  # Boolean properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = true
      expect(sensugo_config[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = false
      expect(sensugo_config[property]).to eq(:false)
    end
    it "should accept valid #{property}" do
      config[property] = 'true'
      expect(sensugo_config[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = 'false'
      expect(sensugo_config[property]).to eq(:false)
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { sensugo_config }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are true, false/)
    end
  end

  # Hash properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      sensugo_config[property] = { 'foo': 'bar' }
      expect(sensugo_config[property]).to eq({'foo': 'bar'})
    end
    it "should not accept invalid #{property}" do
      sensugo_config[property] = 'foo'
      expect { sensugo_config }.to raise_error(Puppet::Error, /should be a Hash/)
    end
  end

  include_examples 'autorequires', false do
    let(:res) { sensugo_config }
  end

  [
    :value,
  ].each do |property|
    it "should require property when ensure => present" do
      config.delete(property)
      config[:ensure] = :present
      expect { sensugo_config }.to raise_error(Puppet::Error, /You must provide a #{property}/)
    end
  end
end
