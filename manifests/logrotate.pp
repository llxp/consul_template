class consul_template::logrotate(
  $service_name           = '',
  $logrotate_compress     = '',
  $logrotate_files        = '',
  $logrotate_on           = false,
  $logrotate_period       = '',
  String $restart_sysv    = "/sbin/service consul-template-${service_name} restart",
  String $restart_systemd = '/bin/systemctl restart consul-template-${service_name}.service',
) {

 case $facts['os']['family'] {
    'RedHat': {
      case $facts['os']['name'] {
        'RedHat', 'CentOS', 'OracleLinux', 'Scientific': {
          if(versioncmp($facts['os']['release']['major'], '7') > 0) {
            $postrotate_command = $restart_systemd
          }
          elsif (versioncmp($facts['os']['release']['major'], '7') < 0) {
            $postrotate_command = $restart_sysv
          }
          else {
            $postrotate_command = $restart_systemd
          }
        }
        'Amazon': {
          $postrotate_command = $restart_sysv
        }
        default: {
          $postrotate_command = $restart_sysv
        }
      }
    }
    default: {
      $postrotate_command = $restart_sysv
    }
  }

  if $logrotate_on {
    file { '/etc/logrotate.d/consul-template':
      ensure  => file,
      content => template("${module_name}/consul-template.logrotate.erb"),
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
    }
  }

}
