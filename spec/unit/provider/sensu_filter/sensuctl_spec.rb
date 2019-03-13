require 'spec_helper'

describe Puppet::Type.type(:sensugo_filter).provider(:sensuctl) do
  before(:each) do
    @provider = described_class
    @type = Puppet::Type.type(:sensugo_filter)
    @resource = @type.new({
      :name => 'test',
      :action => 'allow',
      :expressions => ["event.Entity.Environment == 'production'"],
    })
  end

  describe 'self.instances' do
    it 'should create instances' do
      allow(@provider).to receive(:sensuctl_list).with('filter').and_return(my_fixture_read('filter_list.json'))
      expect(@provider.instances.length).to eq(1)
    end

    it 'should return the resource for a filter' do
      allow(@provider).to receive(:sensuctl_list).with('filter').and_return(my_fixture_read('filter_list.json'))
      property_hash = @provider.instances[0].instance_variable_get("@property_hash")
      expect(property_hash[:name]).to eq('production_filter')
    end
  end

  describe 'create' do
    it 'should create a filter' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :action => :allow,
        :expressions => ["event.Entity.Environment == 'production'"],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('EventFilter', expected_metadata, expected_spec)
      @resource.provider.create
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash[:ensure]).to eq(:present)
    end
  end

  describe 'flush' do
    it 'should update a filter action' do
      expected_metadata = {
        :name => 'test',
        :namespace => 'default',
      }
      expected_spec = {
        :action => 'deny',
        :expressions => ["event.Entity.Environment == 'production'"],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('EventFilter', expected_metadata, expected_spec)
      @resource.provider.action = 'deny'
      @resource.provider.flush
    end
  end

  describe 'destroy' do
    it 'should delete a filter' do
      expect(@resource.provider).to receive(:sensuctl_delete).with('filter', 'test')
      @resource.provider.destroy
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash).to eq({})
    end
  end
end

