define consul_template::watch(
  $service_name         = '',
  $config_hash          = {},
  $config_defaults      = {},
  $template             = undef,
  $template_vars        = {},
  $pretty_config        = false,
  $pretty_config_indent = 4,
  $config_dir           = '',
  $user                 = '',
  $group                = '',
  $config_mode          = ''
) {

  if $service_name != '' {
    $_service_name = $service_name
  } else {
    $_service_name = 'consul-template'
  }

  $_config_hash = deep_merge($config_defaults, $config_hash)
  if $template == undef and $_config_hash['source'] == undef {
    err ('Specify either template parameter or config_hash["source"] for consul_template::watch')
  }

  if $template != undef and $_config_hash['source'] != undef {
    err ('Specify either template parameter or config_hash["source"] for consul_template::watch - but not both')
  }

  unless $template {
    # source is specified in config_hash
    $config_source = {}
    $frag_name = $_config_hash['source']
    $fragment_requires = undef
  } else {
    # source is specified as a template
    $source = "${config_dir}/${service_name}/${name}.ctmpl"
    $config_source = {
      source => $source,
    }

    file { $source:
      ensure  => 'file',
      owner   => $user,
      group   => $group,
      mode    => $config_mode,
      content => template($template),
      notify  => Service["consul-template-${_service_name}"],
    }

    $frag_name = $source
    $fragment_requires = File[$source]
  }

  $config_hash_all = deep_merge($_config_hash, $config_source)
  $content_full = consul::sorted_json($config_hash_all, $pretty_config, $pretty_config_indent)
  $content = regsubst(regsubst($content_full, "}\n$", '}'), "\n", "\n    ", 'G')

  @concat::fragment { $frag_name:
    target  => "consul-template/${_service_name}/config.json",
    # NOTE: this will result in all watches having , after them in the JSON
    # array. That won't pass strict JSON parsing, but luckily HCL is fine with it.
    content => "      ${content},\n",
    order   => '50',
    notify  => Service["consul-template-${_service_name}"],
    require => $fragment_requires,
  }

}
