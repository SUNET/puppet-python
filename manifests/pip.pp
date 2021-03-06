# == Define: python::pip
#
# Installs and manages packages from pip.
#
# === Parameters
#
# [*name]
#  must be unique
#
# [*pkgname]
#  name of the package.
#
# [*ensure*]
#  present|absent. Default: present
#
# [*virtualenv*]
#  virtualenv to run pip in.
#
# [*url*]
#  URL to install from. Default: none
#
# [*owner*]
#  The owner of the virtualenv being manipulated. Default: root
#
# [*proxy*]
#  Proxy server to use for outbound connections. Default: none
#
# [*environment*]
#  Additional environment variables required to install the packages. Default: none
#
# === Examples
#
# python::pip { 'flask':
#   virtualenv => '/var/www/project1',
#   proxy      => 'http://proxy.domain.com:3128',
# }
#
# === Authors
#
# Sergey Stankevich
# Fotis Gimian
#
define python::pip (
  $pkgname         = undef,
  $ensure          = present,
  $virtualenv      = 'system',
  $url             = false,
  $owner           = 'root',
  $proxy           = false,
  $egg             = false,
  $environment     = [],
  $install_args    = '',
  $uninstall_args  = '',
) {

  # Parameter validation
  if ! $virtualenv {
    fail('python::pip: virtualenv parameter must not be empty')
  }

  if $virtualenv == 'system' and $owner != 'root' {
    fail('python::pip: root user must be used when virtualenv is system')
  }

  $cwd = $virtualenv ? {
    'system' => '/',
    default  => $virtualenv,
  }

  $pip_env = $virtualenv ? {
    'system' => 'pip',
    default  => "${virtualenv}/bin/pip",
  }

  $proxy_flag = $proxy ? {
    false    => '',
    default  => "--proxy=${proxy}",
  }

  $grep_regex = $pkgname ? {
    /==/    => "^${pkgname}\$",
    default => "^${pkgname}==",
  }

  $egg_name = $egg ? {
    false   => $pkgname,
    default => $egg
  }

  $source = $url ? {
    false   => $pkgname,
    default => "${url}#egg=${egg_name}",
  }

  # We need to jump through hoops to make sure we issue the correct pip command
  # depending on wheel support and versions.
  #
  # Pip does not support wheels prior to version 1.4.0
  # Pip wheels require setuptools/distribute > 0.8
  # Python 2.6 and older does not support setuptools/distribute > 0.8
  # Pip >= 1.5 tries to use wheels by default, even if wheel package is not
  # installed, in this case the --no-use-wheel flag needs to be passed
  # Versions prior to 1.5 don't support the --no-use-wheel flag
  #
  # To check for this we test for wheel parameter using help and then using
  # version, this makes sure we only use wheels if they are supported and
  # installed


  case $ensure {
    present: {
      exec { "pip_install_${name}":
        command     => "${pip_env} wheel --help > /dev/null 2>&1 && { ${pip_env} wheel --version > /dev/null 2>&1 || wheel_support_flag='--no-use-wheel'; } ; ${pip_env} --log ${cwd}/pip.log install ${install_args} \$wheel_support_flag ${proxy_flag} ${source}",
        unless      => "${pip_env} freeze | grep -i -e ${grep_regex}",
        user        => $owner,
        environment => $environment,
        path        => ['/usr/local/bin','/usr/bin','/bin', '/usr/sbin'],
      }
    }

    latest: {
      exec { "pip_install_${name}":
        command     => "${pip_env} wheel --help > /dev/null 2>&1 && { ${pip_env} wheel --version > /dev/null 2>&1 || wheel_support_flag='--no-use-wheel'; } ; ${pip_env} --log ${cwd}/pip.log install --upgrade \$wheel_support_flag ${proxy_flag} ${source}",
        user        => $owner,
        environment => $environment,
        path        => ['/usr/local/bin','/usr/bin','/bin', '/usr/sbin'],
      }
    }

    default: {
      exec { "pip_uninstall_${name}":
        command     => "echo y | ${pip_env} uninstall ${uninstall_args} ${proxy_flag} ${pkgname}",
        onlyif      => "${pip_env} freeze | grep -i -e ${grep_regex}",
        user        => $owner,
        environment => $environment,
        path        => ['/usr/local/bin','/usr/bin','/bin', '/usr/sbin'],
      }
    }
  }

}
