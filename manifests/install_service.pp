define consul_template::install_service(
  $service_name   = '',
  $data_dir       = '',
  $bin_dir        = '',
  $user           = 'root',
  $group          = 'root',
  $init_style     = '',
  $config_dir     = '',
  $extra_options  = ''
) {

  if ! empty($data_dir) {
    file { $data_dir:
      ensure => 'directory',
      owner  => $user,
      group  => $group,
      mode   => '0755',
    }
  }

  if $init_style {
    case $init_style {
      'upstart' : {
        notify { "install ${service_name} as upstart service": }
        file { "/etc/init/consul-template-${service_name}.conf":
          mode    => '0444',
          owner   => 'root',
          group   => 'root',
          content => template("${module_name}/consul-template.upstart.erb"),
        }
        file { "/etc/init.d/consul-template-${service_name}":
          ensure => link,
          target => '/lib/init/upstart-job',
          owner  => root,
          group  => root,
          mode   => '0755',
        }
      }
      'systemd' : {
        notify { "install ${service_name} as systemd service": }
        file { "/lib/systemd/system/consul-template-${service_name}.service":
          mode    => '0644',
          owner   => 'root',
          group   => 'root',
          content => template("${module_name}/consul-template.systemd.erb"),
        }
      }
      'sysv' : {
        notify { "install ${service_name} as sysv service": }
        file { "/etc/init.d/consul-template-${service_name}":
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template("${module_name}/consul-template.sysv.erb")
        }
      }
      'debian' : {
        notify { "install ${service_name} as debian service": }
        file { "/etc/init.d/consul-template-${service_name}":
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template("${module_name}/consul-template.debian.erb")
        }
      }
      'sles' : {
        notify { "install ${service_name} as sles service": }
        file { "/etc/init.d/consul-template-${service_name}":
          mode    => '0555',
          owner   => 'root',
          group   => 'root',
          content => template("${module_name}/consul-template.sles.erb")
        }
      }
      default : {
        fail("I don't know how to create an init script for style ${init_style}")
      }
    }
  }

}
