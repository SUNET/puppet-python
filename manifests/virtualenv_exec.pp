# == Define: python::virtualenv_exec
#
# Creates Python virtualenv_exec.
#
# === Parameters
#
# [*environment*]
#  Additional environment variables required to install the packages. Default: none
#
# [*path*]
#  Specifies the PATH variable. Default: [ '/bin', '/usr/bin', '/usr/sbin' ]
#
# [*cwd*]
#  The directory from which to run the "pip install" command. Default: /tmp
#
# [*command*]
# The command you want to run in the virtualenv
#
# [*exec_unless*]
# Do not execute the command if eval is true. Default false
#
# === Examples
#
# python::virtualenv { '/var/www/project1':
#   command      => 'django-admin.py collectstatic --settings=peer.settings',
#   exec_unless  => 'ls /tmp/foo >/dev/null',
# }
#
# === Authors
#
# Sergey Stankevich
# Ashley Penney
# Marc Fournier
# Fotis Gimian
# Anders Lördal
#
define python::virtualenv_exec (
  $environment  = [],
  $path         = [ '/bin', '/usr/bin', '/usr/sbin','/usr/local/bin' ],
  $cwd          = "/tmp",
  $command      = '',
  $exec_unless  = 'false',
) {

  $venv_dir = $name

  exec { "python_virtualenv_exec_${venv_dir}":
    command     => "/bin/bash -lic 'source ${venv_dir}/bin/activate && ${command}'",
    user        => $owner,
    path        => $path,
    cwd         => $cwd,
    environment => $environment,
    unless      => $exec_unless,
  }
}
