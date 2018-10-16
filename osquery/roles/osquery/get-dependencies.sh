#!/bin/sh
## one script to be used by travis, jenkins, packer...

umask 022

if [ $# != 0 ]; then
rolesdir=$1
else
rolesdir=$(dirname $0)/..
fi

[ ! -d $rolesdir/juju4.redhat-epel ] && git clone https://github.com/juju4/ansible-redhat-epel $rolesdir/juju4.redhat-epel
[ ! -d $rolesdir/geerlingguy.redis ] && git clone https://github.com/juju4/ansible-role-redis.git $rolesdir/geerlingguy.redis
[ ! -d $rolesdir/geerlingguy.mysql ] && git clone https://github.com/geerlingguy/ansible-role-mysql.git $rolesdir/geerlingguy.mysql
[ ! -d $rolesdir/juju4.kolide ] && git clone https://github.com/juju4/ansible-kolide $rolesdir/juju4.kolide
## galaxy naming: kitchen fails to transfer symlink folder
#[ ! -e $rolesdir/kbrebanov.osquery ] && ln -s ansible-osquery $rolesdir/kbrebanov.osquery
[ ! -e $rolesdir/kbrebanov.osquery ] && cp -R $rolesdir/ansible-osquery $rolesdir/kbrebanov.osquery

## don't stop build on this script return code
true

