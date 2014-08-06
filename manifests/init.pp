# == Class: bootserver
#
# Full description of class bootserver here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { bootserver:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class bootserver (
  $szDnsmasqProcessOwnerName = 'nobody'
  $szWebProcessOwnerName = 'lighttpd'
  # This information should probably go into hiera.
  $szIpAddressForSupportingKickStart
  # This is the C class subnet address, used by the dnsmasq.conf template
  $szClassCSubnetAddress
  $szTftpBaseDirectory = '/var/tftp'
  $szKickStartBaseDirectory = '/var/ks'
)
{
  # Create a kickstart server that will host files over NFS.

  # This is the directory where the kick start configuration files are stored.
  # This is exported via NFS.
  $szKickStartConfsDir      = "$szKickStartBaseDirectory/configs"

  # This is where ??? is stored?
  $szKickStartImageDir      = "$szKickStartBaseDirectory/images"

  # TODO C Use this both for post pkg install as well as kickstart installs.
  $szKickStartRepoExtrasDir = "$szKickStartBaseDirectory/extrarepos"

  $szKickStartPuppetExtrasDir = "$szKickStartBaseDirectory/puppetextras"

  $szDnsMasqBaseDirectory = "/etc/dnsmasq.d"

  $szDnsMasqStaticDirectory = "$szDnsMasqBaseDirectory/static"

  $szDnsMasqHostConfigurationName = "hosts.conf"

file { $szKickStartBaseDirectory:
  ensure => directory,
}

file { $szKickStartConfsDir:
  ensure  => directory,
  require => File [ $szKickStartBaseDirectory ],
}

file { $szKickStartImageDir:
  ensure  => directory,
  require => File [ $szKickStartBaseDirectory ],
}


# ===== DNSMASQ
package { 'dnsmasq':
  ensure => present,
}

service { 'dnsmasq':
  ensure  => running,
  require => Package [ 'dnsmasq'],
}


# http://blogging.dragon.org.uk/index.php/mini-howtos/howto-setup-dnsmasq-on-fedora

# dnsmasq.conf
file { $szDnsMasqBaseDirectory:
  ensure  => directory,
  require => [ Package [ 'dnsmasq' ], File [ $szTftpBaseDirectory ], ],
}


file { $szDnsMasqStaticDirectory:
  ensure  => directory,
  require => File [ $szDnsMasqBaseDirectory ],
}

file { '/etc/dnsmasq.conf':
  ensure  => present,
  content => template('/vagrant/templates/dnsmasq_conf.erb'),
  require => File [ $szDnsMasqStaticDirectory ],
  notify  => Service [ 'dnsmasq' ]
}

file { "$szDnsMasqStaticDirectory/$szDnsMasqHostConfigurationName":
  ensure  => present,
  require => File [ $szDnsMasqStaticDirectory ],
}

file { $szTftpBaseDirectory:
  ensure  => directory,
  owner   => $szDnsmasqProcessOwnerName,
}

# TODO put the freaking SELinux into permisive mode to allow dnsmaq to run.


package { 'syslinux':
  ensure => present,
}

file { "$szTftpBaseDirectory/pxelinux.0":
  ensure  => file,
  source  => '/usr/share/syslinux/pxelinux.0',
  owner   => $szDnsmasqProcessOwnerName,
  mode    => 444,
  require => Package[ 'syslinux' ],
}

file { "$szTftpBaseDirectory/pxelinux.cfg":
  ensure  => directory,
  owner   => $szDnsmasqProcessOwnerName,
  mode    => 444,
  require => File [ $szTftpBaseDirectory ],
}

file { "$szTftpBaseDirectory/pxelinux.cfg/default":
  ensure  => file,
  source  => '/vagrant/files/pxe_cfg_default',
  owner   => $szDnsmasqProcessOwnerName,
  mode    => 444,
  require => File [ "$szTftpBaseDirectory/pxelinux.cfg" ],
}

# ------------------  Create the host repo thing.
# This for creating the repo for the packages that are not in the images (the copy of the ISOs).
# See: http://www.techrepublic.com/blog/linux-and-open-source/create-your-own-yum-repository/609/
package { 'createrepo':
  ensure => present,
}

file { "$szKickStartRepoExtrasDir":
  ensure  => directory,
  owner   => $szWebProcessOwnerName,
  require => File [ "$szKickStartBaseDirectory" ],
}


file { "$szKickStartPuppetExtrasDir":
  ensure => directory,
  owner   => $szWebProcessOwnerName,
  require => File [ "$szKickStartBaseDirectory" ],
}


}
