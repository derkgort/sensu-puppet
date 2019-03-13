require_relative '../../puppet_x/sensu/type'
require_relative '../../puppet_x/sensu/array_property'
require_relative '../../puppet_x/sensu/hash_property'
require_relative '../../puppet_x/sensu/integer_property'

Puppet::Type.newtype(:sensugo_mutator) do
  desc <<-DESC
@summary Manages Sensu mutators
@example Create a mutator
  sensugo_mutator { 'example':
    ensure  => 'present',
    command => 'example-mutator.rb',
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
    desc "The name of the mutator."
    validate do |value|
      unless value =~ /^[\w\.\-]+$/
        raise ArgumentError, "sensugo_mutator name invalid"
      end
    end
  end

  newproperty(:command) do
    desc "The mutator command to be executed."
  end

  newproperty(:timeout, :parent => PuppetX::Sensugo::IntegerProperty) do
    desc "The mutator execution duration timeout in seconds (hard stop)"
    newvalues(/^[0-9]+$/, :absent)
  end

  newproperty(:runtime_assets, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "An array of Sensu assets (names), required at runtime for the execution of the command"
    newvalues(/.*/, :absent)
  end

  newproperty(:env_vars, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "An array of environment variables to use with command execution."
    newvalues(/.*/, :absent)
  end

  newproperty(:namespace) do
    desc "The Sensu RBAC namespace that this mutator belongs to."
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
      :command,
    ]
    required_properties.each do |property|
      if self[:ensure] == :present && self[property].nil?
        fail "You must provide a #{property}"
      end
    end
  end
end
