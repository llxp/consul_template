# @summary A short summary of the purpose of this defined type.
#
# A description of what this defined type does
#
# @example
#   consul_template { 'namevar': }
define consul_template (
  String $arch                               = '',
  String $init_style                         = '',
  String $os                                 = '',
  String $version                            = '0.24.1',
  Hash $watches                              = {},
  String $config_dir                         = '/etc/consul-template',
  String $data_dir                           = '',
  String $bin_dir                            = '/usr/local/bin',
  Hash $config_hash                          = {},
  Hash $config_defaults                      = {},
  String $config_mode                        = '0660',
  Optional[Stdlib::HTTPSUrl] $download_url   = undef,
  Stdlib::HTTPSUrl $download_url_base        = 'https://releases.hashicorp.com/consul-template',
  String $download_extension                 = 'zip',
  $extra_options                             = '',
  $group                                     = 'root',
  Enum['url', 'package'] $install_method     = 'url',
  $logrotate_compress                        = 'nocompress',
  $logrotate_files                           = 4,
  $logrotate_on                              = false,
  $logrotate_period                          = 'daily',
  $manage_user                               = false,
  $manage_group                              = false,
  $package_name                              = 'consul-template',
  $package_ensure                            = 'latest',
  $pretty_config                             = false,
  $pretty_config_indent                      = 4,
  $purge_config_dir                          = true,
  $service_enable                            = true,
  Enum['stopped', 'running'] $service_ensure = 'running',
  $user                                      = 'root',
  $service_name                              = $title
) {

  $rnd_string = seeded_rand_string(10, '', 'abcdefghijklmnopqrstuvwxyz')

  include consul_template::params
  if $arch == '' {
    $_arch = $consul_template::params::arch
  } else {
    $_arch = $arch
  }
  if $os == '' {
    $_os = $consul_template::params::os
  } else {
    $_os = $os
  }
  if $init_style == '' {
    $_init_style = $consul_template::params::init_style
  } else {
    $_init_style = $init_style
  }

  $_download_url = pick($download_url, "${download_url_base}/${version}/${package_name}_${version}_${_os}_${_arch}.${download_extension}")

  if $watches {
    $watch_default = {
      'config_dir'   => $config_dir,
      'service_name' => $service_name,
      'user'         => $user,
      'group'        => $group,
      'config_mode'  => $config_mode 
    }
    create_resources('consul_template::watch', $watches, $watch_default)
  }

  #if ! defined(Class['consul_template::install']) {
    #class { 'consul_template::install':
  consul_template::install { "install: ${service_name}":
      version        => $version,
      bin_dir        => $bin_dir,
      install_method => $install_method,
      download_url   => $_download_url,
      manage_user    => $manage_user,
      manage_group   => $manage_group,
      rnd_string     => $rnd_string
    }
  #}

  consul_template::install_service { "install service: ${service_name}":
    service_name   => $service_name,
    data_dir       => $data_dir,
    bin_dir        => $bin_dir,
    user           => $user,
    group          => $group,
    init_style     => $_init_style,
    config_dir     => $config_dir,
    extra_options  => $extra_options
  }

  consul_template::config { "config: ${service_name}":
    service_name    => $service_name,
    user            => $user,
    group           => $group,
    config_dir      => $config_dir,
    config_defaults => $config_defaults,
    config_hash     => $config_hash,
    config_mode     => $config_mode
  }

  consul_template::service { "service: ${service_name}":
    service_name    => $service_name,
    init_style      => $_init_style,
    service_enable  => $service_enable,
    service_ensure  => $service_ensure
  }

  #contain consul_template::install
  #contain consul_template::config
  #contain consul_template::service
  #contain consul_template::logrotate

  Consul_template::Install["install: ${service_name}"]
  -> Consul_template::Install_service["install service: ${service_name}"]
  -> Consul_template::Config["config: ${service_name}"]
  ~> Consul_template::Service["service: ${service_name}"]
  #-> Class['consul_template::logrotate']

}
