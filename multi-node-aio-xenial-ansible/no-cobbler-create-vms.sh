#!/usr/bin/env bash
set -eu
# Copyright [2016] [Kevin Carter]
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

# bring in variable definitions if there is a variables.sh file
[[ -f variables.sh ]] && source variables.sh

# Reset the ssh-agent service to remove potential key issues
ssh_agent_reset
# Set the default preseed device name.
#  This is being set because sda is on hosts, vda is kvm, xvda is xen.
DEVICE_NAME="${DEVICE_NAME:-vda}"

# Set Ethernet type
ETH_TYPE="${ETH_TYPE:-eth}"

# Create VM Basic Configuration files
for node_type in $(get_all_types); do
  for node in $(get_host_type ${node_type}); do
    cp -v "templates/vmnode-config/${node_type}.openstackci.local.xml" /etc/libvirt/qemu/${node%%":"*}.openstackci.local.xml
    sed -i "s|__NODE__|${node%%":"*}|g" /etc/libvirt/qemu/${node%%":"*}.openstackci.local.xml
    sed -i "s|__COUNT__|${node:(-2)}|g" /etc/libvirt/qemu/${node%%":"*}.openstackci.local.xml
    sed -i "s|__DEVICE_NAME__|${DEVICE_NAME}|g" /etc/libvirt/qemu/${node%%":"*}.openstackci.local.xml
    sed -i "s|__CONTAINER_VMS__|${CONTAINER_VMS}|g" /etc/libvirt/qemu/${node%%":"*}.openstackci.local.xml
  done
done
# Populate network configurations based on node type
for node_type in $(get_all_types); do
  for node in $(get_host_type ${node_type}); do
    sed -e "s/__COUNT__/${node#*":"}/g" -e "s/__DEFAULT_NETWORK__/${DEFAULT_NETWORK}/g" -e "s/__NETWORK_BASE__/${NETWORK_BASE}/g" -e "s/__ETH_TYPE__/${ETH_TYPE}/g" "templates/network-interfaces/vm.openstackci.local-bonded-bridges.cfg" > "/var/www/html/osa-${node%%":"*}-bridges.cfg"
  done
done
# Kick all of the VMs to run the cloud
#  !!!THIS TASK WILL DESTROY ALL OF THE ROOT DISKS IF THEY ALREADY EXIST!!!
rekick_vms
