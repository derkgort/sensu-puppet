require_relative '../../puppet_x/sensu/type'
require_relative '../../puppet_x/sensu/array_property'
require_relative '../../puppet_x/sensu/hash_property'
require_relative '../../puppet_x/sensu/integer_property'

Puppet::Type.newtype(:sensugo_config) do
  desc <<-DESC
@summary Manages Sensu configs
@example Manage a config
  sensugo_config { 'format':
    value => 'json',
  }

**Autorequires**:
* `Package[sensu-go-cli]`
* `Service[sensu-backend]`
* `sensugo_configure[puppet]`
* `sensugo_api_validator[sensu]`
DESC

  extend PuppetX::Sensugo::Type
  add_autorequires(false)

  ensurable do
    desc "The basic property that the resource should be in."
    defaultvalues
    validate do |value|
      if value.to_sym == :absent
        raise ArgumentError, "sensugo_config ensure does not support absent"
      end
    end
  end

  newparam(:name, :namevar => true) do
    desc "The name of the config."
    validate do |value|
      unless value =~ /^[\w\.\-\_]+$/
        raise ArgumentError, "sensugo_config name invalid"
      end
    end
  end

  newproperty(:value) do
    desc "The value of the config."
    munge do |value|
      value.to_s
    end
  end

  validate do
    required_properties = [
      :value,
    ]
    required_properties.each do |property|
      if self[:ensure] == :present && self[property].nil?
        fail "You must provide a #{property}"
      end
    end
  end
end
