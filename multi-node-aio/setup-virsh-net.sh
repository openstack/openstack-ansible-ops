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

# Remove the default libvirt networks
if virsh net-list |  grep -qw "default"; then
  virsh net-autostart default --disable
  virsh net-destroy default
fi

# Create the libvirt networks used for the Host VMs
for network in br-dhcp vm-br-eth1 vm-br-eth2 vm-br-eth3 vm-br-eth4 vm-br-eth5; do
  if ! virsh net-list |  grep -qw "${network}"; then
    sed "s/__NETWORK__/${network}/g" templates/libvirt-network.xml > /etc/libvirt/qemu/networks/${network}.xml
    virsh net-define --file /etc/libvirt/qemu/networks/${network}.xml
    virsh net-create --file /etc/libvirt/qemu/networks/${network}.xml
    virsh net-autostart ${network}
  fi
done
