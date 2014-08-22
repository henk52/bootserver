bootserver
==========

Puppet module for creating a boot server.


DNSMAQ needs to have the following ports open:
* dhcp
* dns
* tftp

Example of how to get the port list

sudo ps -ef | grep dns
nobody    9003     1  0 22:02 ?        00:00:00 /usr/sbin/dnsmasq -k
ME       11812  5704  0 23:27 pts/1    00:00:00 grep --color=auto dns
[cadm@localhost distribution-manager]$ sudo lsof -i | grep 9003
dnsmasq   9003   nobody    4u  IPv4  47669      0t0  UDP *:bootps 
dnsmasq   9003   nobody    6u  IPv4  47672      0t0  UDP *:domain 
dnsmasq   9003   nobody    7u  IPv4  47673      0t0  TCP *:domain (LISTEN)
dnsmasq   9003   nobody    8u  IPv4  47674      0t0  UDP *:tftp 
dnsmasq   9003   nobody    9u  IPv6  47675      0t0  UDP *:domain 
dnsmasq   9003   nobody   10u  IPv6  47676      0t0  TCP *:domain (LISTEN)
dnsmasq   9003   nobody   11u  IPv6  47677      0t0  UDP *:tftp 

#### /dev/root does not exist

Using the mirror for F20.

Fix: (I had to put the Fedora OS on the 'nfs' line.
nfs --server=10.1.233.3 --dir=/home/ks/repo/linux/releases/20/Fedora/x86_64/os
repo --name=f20_x86_64_os --baseurl=nfs://10.1.233.3:/home/ks/repo/linux/releases/20/Everything/x86_64/os

#### Can't use extra repo
https://bugzilla.redhat.com/show_bug.cgi?id=507093

The '//' for NFS has to be removed.

nfs --server=10.1.2.3 --dir=/home/ks/repo/linux/releases/20/Fedora/x86_64/os
repo --name=f20_x86_64_update --baseurl=nfs:10.1.2.3:/home/ks/repo/linux/updates/20/x86_64
repo --name=f20_x86_64_everything --baseurl=nfs:10.1.2.3:/home/ks/repo/linux/releases/20/Everything/x86_64/os

