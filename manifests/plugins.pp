# @summary Manage Sensu plugins
#
# Class to manage the Sensu plugins.
#
# @example
#   class { 'sensugo::plugins':
#     plugins    => ['disk-checks'],
#     extensions => ['graphite'],
#   }
#
# @example
#   class { 'sensugo::plugins':
#     plugins    => {
#       'disk-checks' => { 'version' => 'latest' },
#     },
#     extensions => {
#       'graphite' => { 'version' => 'latest' },
#     },
#   }
#
# @param package_ensure
#   Ensure property for sensu plugins package.
# @param package_name
#   Name of the Sensu plugins ruby package.
# @param dependencies
#   Package dependencies needed to install plugins and extensions.
#   Default is OS dependent.
# @param plugins
#   Plugins to install
# @param extensions
#   Extensions to install
#
class sensugo::plugins (
  String $package_ensure = 'installed',
  String $package_name = 'sensu-plugins-ruby',
  Array $dependencies = [],
  Variant[Array, Hash] $plugins = [],
  Variant[Array, Hash] $extensions = [],
) {

  include ::sensugo

  if $::sensugo::manage_repo {
    include ::sensugo::repo::community
    $package_require = [Class['::sensugo::repo::community']] + $::sensugo::os_package_require
  } else {
    $package_require = undef
  }

  package { 'sensu-plugins-ruby':
    ensure  => $package_ensure,
    name    => $package_name,
    require => $package_require,
  }

  ensure_packages($dependencies)
  $dependencies.each |$package| {
    Package[$package] -> sensugo_plugin <| |> # lint:ignore:spaceship_operator_without_tag
  }

  if $plugins =~ Array {
    $plugins.each |$plugin| {
      sensugo_plugin { $plugin:
        ensure => 'present',
      }
    }
  } else {
    $plugins.each |$plugin, $plugin_data| {
      $data = { 'ensure' => 'present' } + $plugin_data
      sensugo_plugin { $plugin:
        * => $data,
      }
    }
  }

  if $extensions =~ Array {
    $extensions.each |$extension| {
      sensugo_plugin { $extension:
        ensure    => 'present',
        extension => true,
      }
    }
  } else {
    $extensions.each |$extension, $extension_data| {
      $data = { 'ensure' => 'present', 'extension' => true } + $extension_data
      sensugo_plugin { $extension:
        * => $data,
      }
    }
  }

}
