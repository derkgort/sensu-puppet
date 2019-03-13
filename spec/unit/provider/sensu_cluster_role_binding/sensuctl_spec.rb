require 'spec_helper'

describe Puppet::Type.type(:sensugo_cluster_role_binding).provider(:sensuctl) do
  before(:each) do
    @provider = described_class
    @type = Puppet::Type.type(:sensugo_cluster_role_binding)
    @resource = @type.new({
      :name => 'test',
      :role_ref => 'test-role',
      :subjects => [{'type' => 'User', 'name' => 'test-user'}],
    })
  end

  describe 'self.instances' do
    it 'should create instances' do
      allow(@provider).to receive(:sensuctl_list).with('cluster-role-binding', false).and_return(my_fixture_read('list.json'))
      expect(@provider.instances.length).to eq(3)
    end

    it 'should return the resource for a cluster_role_binding' do
      allow(@provider).to receive(:sensuctl_list).with('cluster-role-binding', false).and_return(my_fixture_read('list.json'))
      property_hash = @provider.instances.select {|i| i.name == 'cluster-admin'}[0].instance_variable_get("@property_hash")
      expect(property_hash[:name]).to eq('cluster-admin')
      expect(property_hash[:role_ref]).to eq('cluster-admin')
    end
  end

  describe 'create' do
    it 'should create a cluster_role_binding' do
      expected_metadata = {
        :name => 'test',
      }
      expected_spec = {
        :role_ref => {'type': 'ClusterRole', 'name': 'test-role'},
        :subjects => [{'type' => 'User', 'name' => 'test-user'}],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('ClusterRoleBinding', expected_metadata, expected_spec)
      @resource.provider.create
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash[:ensure]).to eq(:present)
    end
  end

  describe 'flush' do
    it 'should update a cluster_role_binding subjects' do
      expected_metadata = {
        :name => 'test',
      }
      expected_spec = {
        :role_ref => {'type': 'ClusterRole', 'name': 'test-role'},
        :subjects => [{'type' => 'User', 'name' => 'test'}],
      }
      expect(@resource.provider).to receive(:sensuctl_create).with('ClusterRoleBinding', expected_metadata, expected_spec)
      @resource.provider.subjects = [{'type' => 'User', 'name' => 'test'}]
      @resource.provider.flush
    end
  end

  describe 'destroy' do
    it 'should delete a cluster_role_binding' do
      expect(@resource.provider).to receive(:sensuctl_delete).with('cluster-role-binding', 'test')
      @resource.provider.destroy
      property_hash = @resource.provider.instance_variable_get("@property_hash")
      expect(property_hash).to eq({})
    end
  end
end

