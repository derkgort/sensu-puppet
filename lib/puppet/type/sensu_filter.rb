require_relative '../../puppet_x/sensu/type'
require_relative '../../puppet_x/sensu/array_property'
require_relative '../../puppet_x/sensu/hash_property'
require_relative '../../puppet_x/sensu/integer_property'

Puppet::Type.newtype(:sensugo_filter) do
  desc <<-DESC
@summary Manages Sensu filters
@example Create a filter
  sensugo_filter { 'test':
    ensure      => 'present',
    action      => 'allow',
    expressions => ["event.Entity.Environment == 'production'"],
  }

**Autorequires**:
* `Package[sensu-go-cli]`
* `Service[sensu-backend]`
* `sensugo_configure[puppet]`
* `sensugo_api_validator[sensu]`
* `sensugo_namespace` - Puppet will autorequire `sensugo_namespace` resource defined in `namespace` property.
* `sensugo_asset` - Puppet will autorequire `sensugo_asset` resources defined in `runtime_assets` property.
DESC

  extend PuppetX::Sensugo::Type
  add_autorequires()

  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the filter."
    validate do |value|
      unless value =~ /^[\w\.\-]+$/
        raise ArgumentError, "sensugo_filter name invalid"
      end
    end
  end

  newproperty(:action) do
    desc "Action to take with the event if the filter expressions match."
    newvalues('allow', 'deny')
  end

  newproperty(:expressions, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "Filter expressions to be compared with event data."
  end

  newproperty(:runtime_assets, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "Assets to be applied to the filter’s execution context."
    newvalues(/.*/, :absent)
  end

  newproperty(:namespace) do
    desc "The Sensu RBAC namespace that this filter belongs to."
    defaultto 'default'
  end

  newproperty(:labels, :parent => PuppetX::Sensugo::HashProperty) do
    desc "Custom attributes to include with event data, which can be queried like regular attributes."
  end

  newproperty(:annotations, :parent => PuppetX::Sensugo::HashProperty) do
    desc "Arbitrary, non-identifying metadata to include with event data."
  end

  autorequire(:sensugo_asset) do
    self[:runtime_assets]
  end

  validate do
    required_properties = [
      :action,
      :expressions
    ]
    required_properties.each do |property|
      if self[:ensure] == :present && self[property].nil?
        fail "You must provide a #{property}"
      end
    end
  end
end
