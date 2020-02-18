define consul_template::install(
  $version        = '',
  $data_dir       = '',
  $bin_dir        = '',
  $install_method = '',
  $download_url   = '',
  $package_name   = '',
  $package_ensure = '',
  $manage_user    = false,
  $manage_group   = false,
  $rnd_string     = ''
) {

  if $install_method == 'url' {
    include archive

    if $facts['os']['name'] != 'darwin' {
       ensure_packages(['tar'])
    }

    #$rnd_string = seeded_rand_string(10, 'abcdefghijklmnopqrstuvwxyz')
    ensure_resource('archive', "/tmp/consul-template-${version}_${rnd_string}.zip", {
      source       => $download_url,
      extract      => true,
      extract_path => $bin_dir,
      creates      => "${bin_dir}/consul-template",
      cleanup      => true,
    })
    ensure_resource('file', "${bin_dir}/consul-template", {
        owner => 'root',
        group => 0, # 0 instead of root because OS X uses "wheel".
        mode  => '0555'
    })
    Archive["/tmp/consul-template-${version}_${rnd_string}.zip"]
    -> File["${bin_dir}/consul-template"]
  } elsif $install_method == 'package' {
    package { $package_name:
      ensure => $package_ensure,
    }
  } else {
    fail("The provided install method ${install_method} is invalid")
  }

  if $manage_user {
    user { $user:
      ensure => 'present',
      system => true,
    }
  }
  if $manage_group {
    group { $group:
      ensure => 'present',
      system => true,
    }
  }

}
