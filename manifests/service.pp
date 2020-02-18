define consul_template::service(
$service_name   = '',
$init_style     = '',
$service_enable = '',
$service_ensure = ''
) {
  if $init_style == 'sysv' {
    $service_provider = 'redhat'
  } else {
    $service_provider = $init_style
  }

  service { "consul-template-${service_name}":
    ensure   => $service_ensure,
    enable   => $service_enable,
    provider => $service_provider,
    name     => "consul-template-${service_name}",
  }
}
