# @summary Manage Sensu backend
#
# Class to manage the Sensu backend.
#
# @example
#   class { 'sensugo::backend':
#     password => 'secret',
#   }
#
# @param version
#   Version of sensu backend to install.  Defaults to `installed` to support
#   Windows MSI packaging and to avoid surprising upgrades.
# @param package_name
#   Name of Sensu backend package.
# @param cli_package_name
#   Name of Sensu CLI package.
# @param service_name
#   Name of the Sensu backend service.
# @param service_ensure
#   Sensu backend service ensure value.
# @param service_enable
#   Sensu backend service enable value.
# @param state_dir
#   Sensu backend state directory path.
# @param config_hash
#   Sensu backend configuration hash used to define backend.yml.
# @param url_host
#   Sensu backend host used to configure sensuctl and verify API access.
# @param url_port
#   Sensu backend port used to configure sensuctl and verify API access.
# @param ssl_cert_source
#   The SSL certificate source
# @param ssl_key_source
#   The SSL private key source
# @param password
#   Sensu backend admin password used to confiure sensuctl.
# @param old_password
#   Sensu backend admin old password needed when changing password.
# @param agent_password
#   The sensu agent password
# @param agent_old_password
#   The sensu agent old password needed when changing agent_password
# @param include_default_resources
#   Sets if default sensu resources should be included
# @param show_diff
#   Sets show_diff parameter for backend.yml configuration file
# @param license_source
#   The source of sensu-go enterprise license.
#   Supports any valid Puppet File sources such as absolute paths or puppet:///
#   Do not define with license_content
# @param license_content
#   The content of sensu-go enterprise license
#   Do not define with license_source
#
class sensugo::backend (
  Optional[String] $version = undef,
  String $package_name = 'sensu-go-backend',
  String $cli_package_name = 'sensu-go-cli',
  String $service_name = 'sensu-backend',
  String $service_ensure = 'running',
  Boolean $service_enable = true,
  Stdlib::Absolutepath $state_dir = '/var/lib/sensu/sensu-backend',
  Hash $config_hash = {},
  String $url_host = $trusted['certname'],
  Stdlib::Port $url_port = 8080,
  String $ssl_cert_source = $facts['puppet_hostcert'],
  String $ssl_key_source = $facts['puppet_hostprivkey'],
  String $password = 'P@ssw0rd!',
  Optional[String] $old_password = undef,
  String $agent_password = 'P@ssw0rd!',
  Optional[String] $agent_old_password = undef,
  Boolean $include_default_resources = true,
  Boolean $show_diff = true,
  Optional[String] $license_source = undef,
  Optional[String] $license_content = undef,
) {

  if $license_source and $license_content {
    fail('sensugo::backend: Do not define both license_source and license_content')
  }

  include ::sensugo

  $etc_dir = $::sensugo::etc_dir
  $ssl_dir = $::sensugo::ssl_dir
  $use_ssl = $::sensugo::use_ssl
  $_version = pick($version, $::sensugo::version)

  if $use_ssl {
    $url_protocol = 'https'
    $trusted_ca_file = "${ssl_dir}/ca.crt"
    $ssl_config = {
      'cert-file'       => "${ssl_dir}/cert.pem",
      'key-file'        => "${ssl_dir}/key.pem",
      'trusted-ca-file' => $trusted_ca_file,
    }
    $service_subscribe = Class['::sensugo::ssl']
    Class['::sensugo::ssl'] -> sensugo_configure['puppet']
  } else {
    $url_protocol = 'http'
    $trusted_ca_file = 'absent'
    $ssl_config = {}
    $service_subscribe = undef
  }

  $url = "${url_protocol}://${url_host}:${url_port}"
  $default_config = {
    'state-dir' => $state_dir,
    'api-url'   => $url,
  }
  $config = $default_config + $ssl_config + $config_hash


  if $include_default_resources {
    include ::sensugo::backend::resources
  }

  package { 'sensu-go-cli':
    ensure  => $_version,
    name    => $cli_package_name,
    require => $::sensugo::package_require,
  }

  sensugo_api_validator { 'sensu':
    sensugo_api_server => $url_host,
    sensugo_api_port   => $url_port,
    use_ssl          => $use_ssl,
    require          => Service['sensu-backend'],
  }

  sensugo_configure { 'puppet':
    url                => $url,
    username           => 'admin',
    password           => $password,
    bootstrap_password => 'P@ssw0rd!',
    trusted_ca_file    => $trusted_ca_file,
  }
  sensugo_user { 'admin':
    ensure        => 'present',
    password      => $password,
    old_password  => $old_password,
    groups        => ['cluster-admins'],
    disabled      => false,
    configure     => true,
    configure_url => $url,
  }

  if $license_source or $license_content {
    file { 'sensugo_license':
      ensure    => 'file',
      path      => "${etc_dir}/license.json",
      source    => $license_source,
      content   => $license_content,
      owner     => $::sensugo::user,
      group     => $::sensugo::group,
      mode      => '0600',
      show_diff => false,
      notify    => Exec['sensu-add-license'],
    }

    exec { 'sensu-add-license':
      path        => '/usr/bin:/bin:/usr/sbin:/sbin',
      command     => "sensuctl create --file ${etc_dir}/license.json",
      refreshonly => true,
      require     => sensugo_configure['puppet'],
    }
  }

  if $use_ssl {
    file { 'sensugo_ssl_cert':
      ensure    => 'file',
      path      => "${ssl_dir}/cert.pem",
      source    => $ssl_cert_source,
      owner     => $::sensugo::user,
      group     => $::sensugo::group,
      mode      => '0644',
      show_diff => false,
      notify    => Service['sensu-backend'],
    }
    file { 'sensugo_ssl_key':
      ensure    => 'file',
      path      => "${ssl_dir}/key.pem",
      source    => $ssl_key_source,
      owner     => $::sensugo::user,
      group     => $::sensugo::group,
      mode      => '0600',
      show_diff => false,
      notify    => Service['sensu-backend'],
    }
  }

  package { 'sensu-go-backend':
    ensure  => $_version,
    name    => $package_name,
    before  => File['sensugo_etc_dir'],
    require => $::sensugo::package_require,
  }

  file { 'sensugo_backend_state_dir':
    ensure  => 'directory',
    path    => $state_dir,
    owner   => $::sensugo::user,
    group   => $::sensugo::group,
    mode    => '0750',
    require => Package['sensu-go-backend'],
    before  => Service['sensu-backend'],
  }

  file { 'sensugo_backend_config':
    ensure    => 'file',
    path      => "${etc_dir}/backend.yml",
    content   => to_yaml($config),
    show_diff => $show_diff,
    require   => Package['sensu-go-backend'],
    notify    => Service['sensu-backend'],
  }

  service { 'sensu-backend':
    ensure    => $service_ensure,
    enable    => $service_enable,
    name      => $service_name,
    subscribe => $service_subscribe,
  }
}
