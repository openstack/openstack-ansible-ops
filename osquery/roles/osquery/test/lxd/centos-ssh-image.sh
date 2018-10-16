#!/bin/sh
# add ssh to default lxd image

image=centos-7
guest=default-$image
template="$image"-nossh
publishalias="$image"

lxc init $template $guest
lxc start $guest
openssl rand -base64 48 | perl -ne 'print "$_" x2' | lxc exec $guest -- passwd root

lxc exec $guest -- dhclient eth0
lxc exec $guest -- ping -c 1 8.8.8.8
lxc exec $guest -- yum update
lxc exec $guest -- yum -y upgrade
lxc exec $guest -- yum install -y openssh-server sudo ruby yum-utils
lxc exec $guest -- systemctl enable sshd
lxc exec $guest -- systemctl start sshd
lxc exec $guest -- mkdir /root/.ssh || true
lxc exec $guest -- gem install busser

lxc stop $guest --force
lxc publish $guest --alias $publishalias
lxc delete $guest
