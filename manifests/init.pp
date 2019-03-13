# @summary Base Sensu class
#
# This is the main Sensu class
#
# @param version
#   Version of Sensu to install.  Defaults to `installed` to support
#   Windows MSI packaging and to avoid surprising upgrades.
#
# @param etc_dir
#   Absolute path to the Sensu etc directory.
#
# @param ssl_dir
#   Absolute path to the Sensu ssl directory.
#
# @param user
#   User used by sensu services
#
# @param group
#   User group used by sensu services
#
# @param etc_dir_purge
#   Boolean to determine if the etc_dir should be purged
#   such that only Puppet managed files are present.
#
# @param ssl_dir_purge
#   Boolean to determine if the ssl_dir should be purged
#   such that only Puppet managed files are present.
#
# @param manage_repo
#   Boolean to determine if software repository for Sensu
#   should be managed.
#
# @param use_ssl
#   Sensu backend service uses SSL
#
# @param ssl_ca_source
#   Source of SSL CA used by sensu services
#
class sensugo (
  String $version = 'installed',
  Stdlib::Absolutepath $etc_dir = '/etc/sensu',
  Stdlib::Absolutepath $ssl_dir = '/etc/sensu/ssl',
  String $user = 'sensu',
  String $group = 'sensu',
  Boolean $etc_dir_purge = true,
  Boolean $ssl_dir_purge = true,
  Boolean $manage_repo = true,
  Boolean $use_ssl = true,
  String $ssl_ca_source = $facts['puppet_localcacert'],
) {

  file { 'sensugo_etc_dir':
    ensure  => 'directory',
    path    => $etc_dir,
    purge   => $etc_dir_purge,
    recurse => $etc_dir_purge,
    force   => $etc_dir_purge,
  }

  if $use_ssl {
    contain ::sensugo::ssl
  }

  case $facts['os']['family'] {
    'RedHat': {
      $os_package_require = []
    }
    'Debian': {
      $os_package_require = [Class['::apt::update']]
    }
    default: {
      fail("Detected osfamily <${facts['os']['family']}>. Only RedHat and Debian are supported.")
    }
  }

  # $package_require is used by sensugo::agent and sensugo::backend
  # package resources
  if $manage_repo {
    include ::sensugo::repo
    $package_require = [Class['::sensugo::repo']] + $os_package_require
  } else {
    $package_require = undef
  }

}
