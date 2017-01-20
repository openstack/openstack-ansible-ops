#!/usr/bin/env bash
set -eux
# Copyright [2016]
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Load all functions
source functions.rc

# Reset the ssh-agent service to remove potential key issues
ssh_agent_reset

# Ensure dnsmasq process is running, if not, restart lxd-bridge service.
dnsmasq_output=`ps -eo command | grep dnsmasq | grep lxd`
if [[ ! $dnsmasq_output ]]; then
    systemctl restart lxd-bridge
fi

# Create the infra containers, don't fail if it already exists
for i in {1..3}; do
    lxc launch ubuntu:16.04 -p infra infra$i || true
done

# Create compute containers
for i in {1..2}; do
    lxc launch ubuntu:16.04 -p compute compute$i || true
done

# Wait for containers to finish booting
sleep 15

# Move keys over to containers, install common packages
for container in `lxc list -c n | grep -vE '\+|NAME' | awk '{print $2}'`; do
    lxc file push ~/.ssh/id_rsa.pub $container/root/.ssh/authorized_keys
done

# We will do this with lxc file push, then restarting the containers
# Populate network configurations based on node type
for container in `lxc list -c n4 | grep -vE '\+|NAME' | awk '{print $2 ":" $4}'`; do
    IP=`echo $container \ awk -F':' '{print $2}'`
    LAST_OCTET=`echo $container | awk -F':' '{print $2}' | awk -F'.' '{print $4}'`
    NAME=`echo $container | awk -F':' '{print $1}'`
    echo "making interface file for..$LAST_OCTET"
    sed "s/__COUNT__/$LAST_OCTET/g" "templates/network-interfaces/vm.openstackci.local-bonded-bridges.cfg" > "/tmp/$LAST_OCTET.interfaces.cfg"
    lxc file push /tmp/$LAST_OCTET.interfaces.cfg $NAME/etc/network/interfaces.d/
    lxc restart $NAME
done

#for node_type in $(get_all_types); do
#  for node in $(get_host_type ${node_type}); do
#    sed "s/__COUNT__/${node#*":"}/g" "templates/network-interfaces/vm.openstackci.local-bonded-bridges.cfg" > "/var/www/html/osa-${node%%":"*}.openstackci.local-bridges.cfg"
#  done
#done

# Kick all of the VMs to run the cloud
#  !!!THIS TASK WILL DESTROY ALL OF THE ROOT DISKS IF THEY ALREADY EXIST!!!
#rekick_vms

# Wait here for all nodes to be booted and ready with SSH
#wait_ssh

# Ensure that all running VMs have an updated apt-cache
#for node in $(get_all_hosts); do
#  ssh -q -n -f -o StrictHostKeyChecking=no 10.0.0.${node#*":"} "apt-get clean && apt-get update"
#done
