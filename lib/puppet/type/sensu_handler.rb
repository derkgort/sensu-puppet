require_relative '../../puppet_x/sensu/type'
require_relative '../../puppet_x/sensu/array_property'
require_relative '../../puppet_x/sensu/hash_property'
require_relative '../../puppet_x/sensu/integer_property'

Puppet::Type.newtype(:sensugo_handler) do
  desc <<-DESC
@summary Manages Sensu handlers
@example Create a handler
  sensugo_handler { 'test':
    ensure  => 'present',
    type    => 'pipe',
    command => 'notify.rb'
  }

**Autorequires**:
* `Package[sensu-go-cli]`
* `Service[sensu-backend]`
* `sensugo_configure[puppet]`
* `sensugo_api_validator[sensu]`
* `sensugo_namespace` - Puppet will autorequire `sensugo_namespace` resource defined in `namespace` property.
* `sensugo_filter` - Puppet will autorequire `sensugo_filter` resources defined in `filters` property.
* `sensugo_mutator` - Puppet will autorequire `sensugo_mutator` resource defined for `mutator` property.
* `sensugo_handler` - Puppet will autorequire `sensugo_handler` resources defined for `handlers` property.
* `sensugo_asset` - Puppet will autorequire `sensugo_asset` resources defined in `runtime_assets` property.
DESC

  extend PuppetX::Sensugo::Type
  add_autorequires()

  ensurable

  newparam(:name, :namevar => true) do
    desc "The name of the handler."
    validate do |value|
      unless value =~ /^[\w\.\-]+$/
        raise ArgumentError, "sensugo_handler name invalid"
      end
    end
  end

  newproperty(:type) do
    desc "The handler type."
    newvalues('pipe', 'tcp', 'udp', 'set')
  end

  newproperty(:filters, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "An array of Sensu event filters (names) to use when filtering events for the handler."
    newvalues(/.*/, :absent)
  end

  newproperty(:mutator) do
    desc "The Sensu event mutator (name) to use to mutate event data for the handler."
    newvalues(/.*/, :absent)
  end

  newproperty(:timeout, :parent => PuppetX::Sensugo::IntegerProperty) do
    desc "The handler execution duration timeout in seconds (hard stop)"
    newvalues(/^[0-9]+$/, :absent)
    defaultto do
      if ! @resource[:type].nil? && @resource[:type].to_sym == :tcp
        60
      else
        nil
      end
    end
  end

  newproperty(:command) do
    desc "The handler command to be executed."
    newvalues(/.*/, :absent)
  end

  newproperty(:env_vars, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "An array of environment variables to use with command execution."
    newvalues(/.*/, :absent)
  end

  newproperty(:socket_host) do
    desc "The socket host address (IP or hostname) to connect to."
  end

  newproperty(:socket_port, :parent => PuppetX::Sensugo::IntegerProperty) do
    desc "The socket port to connect to."
  end

  newproperty(:handlers, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "An array of Sensu event handlers (names) to use for events using the handler set."
    newvalues(/.*/, :absent)
  end

  newproperty(:runtime_assets, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "An array of Sensu assets (names), required at runtime for the execution of the command"
    newvalues(/.*/, :absent)
  end

  newproperty(:namespace) do
    desc "The Sensu RBAC namespace that this handler belongs to."
    defaultto 'default'
  end

  newproperty(:labels, :parent => PuppetX::Sensugo::HashProperty) do
    desc "Custom attributes to include with event data, which can be queried like regular attributes."
  end

  newproperty(:annotations, :parent => PuppetX::Sensugo::HashProperty) do
    desc "Arbitrary, non-identifying metadata to include with event data."
  end

  autorequire(:sensugo_filter) do
    self[:filters]
  end

  autorequire(:sensugo_mutator) do
    [ self[:mutator] ]
  end

  autorequire(:sensugo_handler) do
    self[:handlers]
  end

  autorequire(:sensugo_asset) do
    self[:runtime_assets]
  end

  validate do
    required_properties = [
      :type,
    ]
    required_properties.each do |property|
      if self[:ensure] == :present && self[property].nil?
        fail "You must provide a #{property}"
      end
    end
    if !self[:command] && self[:type] == :pipe
      fail "command must be defined for type pipe"
    end
    if (self[:type] == :tcp || self[:type] == :udp) &&
        (!self[:socket_host] || !self[:socket_port])
      fail "socket_host and socket_port are required for type tcp or type udp"
    end
    if self[:socket_host] && !self[:socket_port]
      fail "socket_port is required if socket_host is set"
    end
    if !self[:socket_host] && self[:socket_port]
      fail "socket_host is required if socket_port is set"
    end
    if self[:type] == :set && !self[:handlers]
      fail "handlers must be defined for type set"
    end
  end
end
