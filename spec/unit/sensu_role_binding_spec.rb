require 'spec_helper'
require 'puppet/type/sensugo_role_binding'

describe Puppet::Type.type(:sensugo_role_binding) do
  let(:default_config) do
    {
      name: 'test',
      role_ref: 'test',
      subjects: [{'type' => 'User', 'name' => 'test'}],
    }
  end
  let(:config) do
    default_config
  end
  let(:binding) do
    described_class.new(config)
  end

  it 'should add to catalog without raising an error' do
    catalog = Puppet::Resource::Catalog.new
    expect {
      catalog.add_resource binding
    }.to_not raise_error
  end

  it 'should require a name' do
    expect {
      described_class.new({})
    }.to raise_error(Puppet::Error, 'Title or name must be provided')
  end

  defaults = {
    namespace: 'default',
  }

  # String properties
  [
    :namespace,
    :role_ref,
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 'foo'
      expect(binding[property]).to eq('foo')
    end
    if default = defaults[property]
      it "should have default for #{property}" do
        expect(binding[property]).to eq(default)
      end
    end
  end

  # String regex validated properties
  [
  ].each do |property|
    it "should not accept invalid #{property}" do
      config[property] = 'foo bar'
      expect { binding }.to raise_error(Puppet::Error, /#{property.to_s} invalid/)
    end
  end

  # Array properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = ['foo', 'bar']
      expect(binding[property]).to eq(['foo', 'bar'])
    end
  end

  # Integer properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = 30
      expect(binding[property]).to eq(30)
    end
    it "should accept valid #{property} as string" do
      config[property] = '30'
      expect(binding[property]).to eq(30)
    end
    it "should not accept invalid value for #{property}" do
      config[property] = 'foo'
      expect { binding }.to raise_error(Puppet::Error, /should be an Integer/)
    end
  end

  # Boolean properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = true
      expect(binding[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = false
      expect(binding[property]).to eq(:false)
    end
    it "should accept valid #{property}" do
      config[property] = 'true'
      expect(binding[property]).to eq(:true)
    end
    it "should accept valid #{property}" do
      config[property] = 'false'
      expect(binding[property]).to eq(:false)
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { binding }.to raise_error(Puppet::Error, /Invalid value "foo". Valid values are true, false/)
    end
  end

  # Hash properties
  [
  ].each do |property|
    it "should accept valid #{property}" do
      config[property] = { 'foo': 'bar' }
      expect(binding[property]).to eq({'foo': 'bar'})
    end
    it "should not accept invalid #{property}" do
      config[property] = 'foo'
      expect { binding }.to raise_error(Puppet::Error, /should be a Hash/)
    end
  end

  describe 'subjects' do
    it 'accepts valid value' do
      expect(binding[:subjects]).to eq([{'type' => 'User', 'name' => 'test'}])
    end

    it 'should verify subject is a hash' do
      config[:subjects] = ['foo']
      expect { binding }.to raise_error(Puppet::Error, /Each subject must be a Hash/)
    end

    it 'should verify all keys present' do
      config[:subjects] = [{'name' => 'test'}]
      expect { binding }. to raise_error(Puppet::Error, /subject requires key type/)
    end

    it 'should not allow unknown keys' do
      config[:subjects] = [{'name' => 'test', 'type' => 'User', 'foo' => 'bar'}]
      expect { binding }. to raise_error(Puppet::Error, /foo is not a valid subject key/)
    end

    it 'should verify type' do
      config[:subjects] = [{'name' => 'test', 'type' => 'Foo'}]
      expect { binding }. to raise_error(Puppet::Error, /Foo is not a valid type/)
    end
  end

  it 'should autorequire sensugo_role' do
    config[:role_ref] = 'test'
    role = Puppet::Type.type(:sensugo_role).new(:name => 'test', :rules => [{'verbs' => ['get','list'], 'resources' => ['checks']}])
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource binding
    catalog.add_resource role
    rel = binding.autorequire[0]
    expect(rel.source.ref).to eq(role.ref)
    expect(rel.target.ref).to eq(binding.ref)
  end

  it 'should autorequire sensugo_user by user' do
    config[:subjects] = [{'type' => 'User', 'name' => 'test'}]
    user = Puppet::Type.type(:sensugo_user).new(:name => 'test', :groups => ['group'], :password => 'foobar')
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource binding
    catalog.add_resource user
    rel = binding.autorequire[0]
    expect(rel.source.ref).to eq(user.ref)
    expect(rel.target.ref).to eq(binding.ref)
  end

  it 'should autorequire sensugo_user by group' do
    config[:subjects] = [{'type' => 'Group', 'name' => 'group'}]
    user = Puppet::Type.type(:sensugo_user).new(:name => 'test', :groups => ['group'], :password => 'foobar')
    catalog = Puppet::Resource::Catalog.new
    catalog.add_resource binding
    catalog.add_resource user
    rel = binding.autorequire[0]
    expect(rel.source.ref).to eq(user.ref)
    expect(rel.target.ref).to eq(binding.ref)
  end

  include_examples 'autorequires' do
    let(:res) { binding }
  end

  [
    :role_ref,
    :subjects,
  ].each do |property|
    it "should require property when ensure => present" do
      config.delete(property)
      config[:ensure] = :present
      expect { binding }.to raise_error(Puppet::Error, /You must provide a #{property}/)
    end
  end
end
