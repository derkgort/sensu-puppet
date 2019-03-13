require_relative '../../puppet_x/sensu/type'
require_relative '../../puppet_x/sensu/array_property'
require_relative '../../puppet_x/sensu/hash_property'
require_relative '../../puppet_x/sensu/integer_property'

Puppet::Type.newtype(:sensugo_user) do
  desc <<-DESC
@summary Manages Sensu users
@example Create a user
  sensugo_user { 'test':
    ensure   => 'present',
    password => 'supersecret',
    groups   => ['users'],
  }

@example Change a user's password
  sensugo_user { 'test'
    ensure       => 'present',
    password     => 'newpassword',
    old_password => 'supersecret',
    groups       => ['users'],
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
        raise ArgumentError, "sensugo_user ensure does not support absent"
      end
    end
  end

  newparam(:name, :namevar => true) do
    desc "The name of the user."
    validate do |value|
      unless value =~ /^[\w\.\-]+$/
        raise ArgumentError, "sensugo_user name invalid"
      end
    end
  end

  newproperty(:password) do
    desc "The user's password."

    def insync?(is)
      if @resource.provider
        if @resource[:disabled].to_sym == :true
          return true
        end
        @resource.provider.password_insync?(@resource[:name], @should)
      end
    end

    def change_to_s(currentvalue, newvalue)
      return "changed password"
    end
    def is_to_s(currentvalue)
      return '[old password redacted]'
    end
    def should_to_s(newvalue)
      return '[new password redacted]'
    end
  end

  newparam(:old_password) do
    desc "The user's old password, needed in order to change a user's password"
  end

  newproperty(:groups, :array_matching => :all, :parent => PuppetX::Sensugo::ArrayProperty) do
    desc "Groups to which the user belongs."
  end

  newproperty(:disabled, :boolean => true) do
    desc "The state of the user’s account."
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:configure, :boolean => true) do
    desc "Run sensuctl configure for this user"
    newvalues(:true, :false)
    defaultto :false
  end

  newparam(:configure_url) do
    desc "URL to use with 'sensuctl configure'"
    defaultto 'http://127.0.0.1:8080'
  end

  validate do
    required_properties = [
      :password
    ]
    required_properties.each do |property|
      if self[:ensure] == :present && self[property].nil?
        fail "You must provide a #{property}"
      end
    end
  end
end
