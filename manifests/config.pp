define consul_template::config(
  $service_name          = '',
  $config_hash           = {},
  $config_defaults       = {},
  $purge                 = true,
  $config_dir            = '',
  $user                  = '',
  $group                 = '',
  $config_mode           = ''
) {

  $config_base = {
    consul => {
      address => 'localhost:8500',
    }
  }
  $_config_hash = deep_merge($config_base, $config_defaults, $config_hash)

  # Using our parent module's pretty_config & pretty_config_indent just because
  $content_full = consul::sorted_json($_config_hash, $consul_template::pretty_config, $consul_template::pretty_config_indent)
  # remove the closing }
  $content = regsubst($content_full, '}$', '')

  $concat_name = "consul-template/${service_name}/config.json"
  concat::fragment { "${service_name}-consul-service-pre":
    target  => $concat_name,
    # add the opening template array so that we can insert watch fragments
    content => "${content},\n    \"template\": [\n",
    order   => '1'
  }

  # Realizes concat::fragments from consul_template::watches that make up 1 or
  # more template configs.
  Concat::Fragment <| target == $concat_name |>

  concat::fragment { "${service_name}-consul-service-post":
    target  => $concat_name,
    # close off the template array and the whole object
    content => "    ]\n}",
    order   => '99',
  }

  file { ["${config_dir}/${service_name}/", "${config_dir}/${service_name}/config"]:
    ensure  => 'directory',
    purge   => $purge,
    recurse => $purge,
    owner   => $user,
    group   => $group,
    mode    => '0755',
  }
  -> concat { $concat_name:
    path   => "${config_dir}/${service_name}/config/config.json",
    owner  => $user,
    group  => $group,
    mode   => $config_mode,
    notify => Service["consul-template-${service_name}"]
  }

}
