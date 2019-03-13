require_relative '../../puppet_x/sensu/type'
require_relative '../../puppet_x/sensu/array_property'
require_relative '../../puppet_x/sensu/hash_property'
require_relative '../../puppet_x/sensu/integer_property'

Puppet::Type.newtype(:sensugo_namespace) do
  desc <<-DESC
@summary Manages Sensu namespaces
@example Add an namespace
  sensugo_namespace { 'test':
    ensure => 'present',
  }

**Autorequires**:
* `Package[sensu-go-cli]`
* `Service[sensu-backend]`
* `sensugo_configure[puppet]`
* `sensugo_api_validator[sensu]`
DESC

  extend PuppetX::Sensugo::Type
  add_autorequires(false)

  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the namespace."
    validate do |value|
      unless value =~ /^[\w\.\-]+$/
        raise ArgumentError, "sensugo_namespace name invalid"
      end
    end
  end

  validate do
    required_properties = [
    ]
    required_properties.each do |property|
      if self[:ensure] == :present && self[property].nil?
        fail "You must provide a #{property}"
      end
    end
  end
end
