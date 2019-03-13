require File.expand_path(File.join(File.dirname(__FILE__), '..', 'sensuctl'))

Puppet::Type.type(:sensugo_handler).provide(:sensuctl, :parent => Puppet::Provider::Sensuctl) do
  desc "Provider sensugo_handler using sensuctl"

  mk_resource_methods

  def self.instances
    handlers = []

    output = sensuctl_list('handler')
    Puppet.debug("sensu handlers: #{output}")
    begin
      data = JSON.parse(output)
    rescue JSON::ParserError => e
      Puppet.debug('Unable to parse output from sensuctl handler list')
      data = []
    end

    data.each do |d|
      handler = {}
      handler[:ensure] = :present
      handler[:name] = d['metadata']['name']
      handler[:namespace] = d['metadata']['namespace']
      handler[:labels] = d['metadata']['labels']
      handler[:annotations] = d['metadata']['annotations']
      d.each_pair do |key, value|
        next if key == 'metadata'
        next if key == 'socket'
        if !!value == value
          value = value.to_s.to_sym
        end
        if type_properties.include?(key.to_sym)
          handler[key.to_sym] = value
        end
      end
      if d['socket']
        d['socket'].each_pair do |k,v|
          property = "socket_#{k}".to_sym
          if type_properties.include?(property)
            handler[property] = v
          end
        end
      end
      handlers << new(handler)
    end
    handlers
  end

  def self.prefetch(resources)
    handlers = instances
    resources.keys.each do |name|
      if provider = handlers.find { |c| c.name == name }
        resources[name].provider = provider
      end
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end

  def initialize(value = {})
    super(value)
    @property_flush = {}
  end

  type_properties.each do |prop|
    define_method "#{prop}=".to_sym do |value|
      @property_flush[prop] = value
    end
  end

  def create
    spec = {}
    metadata = {}
    metadata[:name] = resource[:name]
    type_properties.each do |property|
      value = resource[property]
      next if value.nil?
      next if value == :absent || value == [:absent]
      next if property.to_s =~ /^socket/
      if [:true, :false].include?(value)
        value = convert_boolean_property_value(value)
      end
      if property == :namespace
        metadata[:namespace] = value
      elsif property == :labels
        metadata[:labels] = value
      elsif property == :annotations
        metadata[:annotations] = value
      else
        spec[property] = value
      end
    end
    if resource[:socket_host] ||  resource[:socket_port]
      spec[:socket] = {}
      spec[:socket][:host] = resource[:socket_host] if resource[:socket_host]
      spec[:socket][:port] = resource[:socket_port] if resource[:socket_port]
    end
    begin
      sensuctl_create('Handler', metadata, spec)
    rescue Exception => e
      raise Puppet::Error, "sensuctl create #{resource[:name]} failed\nError message: #{e.message}"
    end
    @property_hash[:ensure] = :present
  end

  def flush
    if !@property_flush.empty?
      spec = {}
      metadata = {}
      metadata[:name] = resource[:name]
      type_properties.each do |property|
        if @property_flush[property]
          value = @property_flush[property]
        else
          value = resource[property]
        end
        next if value.nil?
        next if property.to_s =~ /^socket/
        if [:true, :false].include?(value)
          value = convert_boolean_property_value(value)
        elsif value == :absent
          value = nil
        end
        if property == :namespace
          metadata[:namespace] = value
        elsif property == :labels
          metadata[:labels] = value
        elsif property == :annotations
          metadata[:annotations] = value
        else
          spec[property] = value
        end
      end
      # Use values from existing resource then overwrite with new values if they exist
      if resource[:socket_host] || resource[:socket_port]
        spec[:socket] = {}
        spec[:socket][:host] = resource[:socket_host] if resource[:socket_host]
        spec[:socket][:port] = resource[:socket_port] if resource[:socket_port]
      end
      if @property_flush[:socket_host] || @property_flush[:socket_port]
        spec[:socket] = {} unless spec[:socket]
        spec[:socket][:host] = @property_flush[:socket_host] if @property_flush[:socket_host]
        spec[:socket][:port] = @property_flush[:socket_port] if @property_flush[:socket_port]
      end
      begin
        sensuctl_create('Handler', metadata, spec)
      rescue Exception => e
        raise Puppet::Error, "sensuctl create #{resource[:name]} failed\nError message: #{e.message}"
      end
    end
    @property_hash = resource.to_hash
  end

  def destroy
    begin
      sensuctl_delete('handler', resource[:name])
    rescue Exception => e
      raise Puppet::Error, "sensuctl delete handler #{resource[:name]} failed\nError message: #{e.message}"
    end
    @property_hash.clear
  end
end

