require 'facter'

module SensuGoFacts
  def self.which(cmd)
    path = Facter::Core::Execution.which(cmd)
    path
  end

  def self.get_version_info(cmd)
    path = self.which(cmd)
    return nil unless path
    output = Facter::Core::Execution.exec("#{path} version 2>&1")
    version = nil
    if output =~ /^#{cmd} version ([^,]+)/
      version = $1.split('#')[0]
    end
    build = nil
    if output =~ /, build ([^,]+)/
      build = $1
    end
    built = nil
    # Match value that is optionally wrapped in single quotes
    if output =~ /built (?:')?([^']+)(?:')?$/
      built = $1
    end
    return version, build, built
  end

  def self.add_facts
    self.add_agent_facts
    self.add_backend_facts
    self.add_sensuctl_facts
  end

  def self.add_agent_facts
    version, build, built = self.get_version_info('sensu-agent')
    agent = {}
    agent['version'] = version unless version.nil?
    agent['build'] = build unless build.nil?
    agent['built'] = built unless built.nil?
    if agent.empty?
      agent = nil
    end

    Facter.add(:sensugo_agent) do
      setcode do
        agent
      end
    end
  end

  def self.add_backend_facts
    version, build, built = self.get_version_info('sensu-backend')
    backend = {}
    backend['version'] = version unless version.nil?
    backend['build'] = build unless build.nil?
    backend['built'] = built unless built.nil?
    if backend.empty?
      backend = nil
    end

    Facter.add(:sensugo_backend) do
      setcode do
        backend
      end
    end
  end

  def self.add_sensuctl_facts
    version, build, built = self.get_version_info('sensuctl')
    sensuctl = {}
    sensuctl['version'] = version unless version.nil?
    sensuctl['build'] = build unless build.nil?
    sensuctl['built'] = built unless built.nil?
    if sensuctl.empty?
      sensuctl = nil
    end

    Facter.add(:sensuctl) do
      setcode do
        sensuctl
      end
    end
  end
end

SensuGoFacts.add_facts
