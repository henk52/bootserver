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
  $szDnsmasqProcessOwnerName = 'nobody',
  $szWebProcessOwnerName = 'lighttpd',
  $szIpAddressForSupportingKickStart = hiera( 'IpAddressForSupportingKickStart' ),
  # This is the Network address e.g. found by applying the netmask(10.1.2.3/24 is 10.1.2.0), used by the dnsmasq.conf template
  $szNetworkAddress = hiera( 'NetworkAddress' ),
  $szTftpBaseDirectory = '/var/tftp',
  $szKickStartBaseDirectory = '/var/ks',
  $szKickStartImageDir = '/var/ks/images',
)
{
  # Create a kickstart server that will host files over NFS.

  # This is the directory where the kick start configuration files are stored.
  # This is exported via NFS.
  $szKickStartConfsDir      = "$szKickStartBaseDirectory/configs"

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
  require => File[ $szKickStartBaseDirectory ],
}

file { $szKickStartImageDir:
  ensure  => directory,
  require => File[ $szKickStartBaseDirectory ],
}


# ===== DNSMASQ
package { 'dnsmasq':
  ensure => present,
}

service { 'dnsmasq':
  ensure  => running,
  enable  => true,
  require => Package[ 'dnsmasq'],
}


# http://blogging.dragon.org.uk/index.php/mini-howtos/howto-setup-dnsmasq-on-fedora

# dnsmasq.conf
file { $szDnsMasqBaseDirectory:
  ensure  => directory,
  require => [ Package[ 'dnsmasq' ], File[ $szTftpBaseDirectory ], ],
}


file { $szDnsMasqStaticDirectory:
  ensure  => directory,
  require => File[ $szDnsMasqBaseDirectory ],
}

file { '/etc/dnsmasq.conf':
  ensure  => present,
  content => template('/etc/puppet/modules/bootserver/templates/dnsmasq_conf.erb'),
  require => File[ $szDnsMasqStaticDirectory ],
  notify  => Service[ 'dnsmasq' ]
}

file { "$szDnsMasqStaticDirectory/$szDnsMasqHostConfigurationName":
  ensure  => present,
  require => File[ $szDnsMasqStaticDirectory ],
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
  mode    => '444',
  require => Package[ 'syslinux' ],
}

# Seems to be a new req in F22.
file { "$szTftpBaseDirectory/ldlinux.c32":
  ensure  => file,
  source  => '/usr/share/syslinux/ldlinux.c32',
  owner   => $szDnsmasqProcessOwnerName,
  mode    => '444',
  require => Package[ 'syslinux' ],
}

file { "$szTftpBaseDirectory/pxelinux.cfg":
  ensure  => directory,
  owner   => $szDnsmasqProcessOwnerName,
  mode    => '444',
  require => File[ $szTftpBaseDirectory ],
}

file { "$szTftpBaseDirectory/pxelinux.cfg/default":
  ensure  => file,
  source  => '/etc/puppet/modules/bootserver/files/pxe_cfg_default',
  owner   => $szDnsmasqProcessOwnerName,
  mode    => '444',
  require => File[ "$szTftpBaseDirectory/pxelinux.cfg" ],
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
  require => File[ "$szKickStartBaseDirectory" ],
}


file { "$szKickStartPuppetExtrasDir":
  ensure => directory,
  owner   => $szWebProcessOwnerName,
  require => File[ "$szKickStartBaseDirectory" ],
}


}
