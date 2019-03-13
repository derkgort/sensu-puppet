# @summary Private class to manage sensu SSL resources
# @api private
#
class sensugo::ssl {
  include ::sensugo

  file { 'sensugo_ssl_dir':
    ensure  => 'directory',
    path    => $::sensugo::ssl_dir,
    purge   => $::sensugo::ssl_dir_purge,
    recurse => $::sensugo::ssl_dir_purge,
    force   => $::sensugo::ssl_dir_purge,
    owner   => $::sensugo::user,
    group   => $::sensugo::group,
    mode    => '0700',
  }

  file { 'sensugo_ssl_ca':
    ensure    => 'file',
    path      => "${::sensugo::ssl_dir}/ca.crt",
    owner     => $::sensugo::user,
    group     => $::sensugo::group,
    mode      => '0644',
    show_diff => false,
    source    => $::sensugo::ssl_ca_source,
  }
}
