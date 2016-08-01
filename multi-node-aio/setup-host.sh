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

# Make the rekick function part of the main general shell
declare -f rekick_vms | tee /root/.functions.rc
declare -f ssh_agent_reset | tee -a /root/.functions.rc
if ! grep -q 'source /root/.functions.rc' /root/.bashrc; then
  echo 'source /root/.functions.rc' | tee -a /root/.bashrc
fi

# Reset the ssh-agent service to remove potential key issues
ssh_agent_reset

if [ ! -f "/root/.ssh/id_rsa" ];then
  ssh-keygen -t rsa -N '' -f /root/.ssh/id_rsa
fi

# This gets the root users SSH-public-key
SSHKEY=$(cat /root/.ssh/id_rsa.pub)
if ! grep -q "${SSHKEY}" /root/.ssh/authorized_keys; then
  cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys
fi

# Install basic packages known to be needed
apt-get update && apt-get install -y bridge-utils ifenslave libvirt-bin lvm2 openssh-server python2.7 qemu-kvm vim virtinst virt-manager vlan

if ! grep "^source.*cfg$" /etc/network/interfaces; then
  echo 'source /etc/network/interfaces.d/*.cfg' | tee -a /etc/network/interfaces
fi

# create kvm bridges
cp -v templates/kvm-bonded-bridges.cfg /etc/network/interfaces.d/kvm-bridges.cfg
for i in $(awk '/iface/ {print $2}' /etc/network/interfaces.d/kvm-bridges.cfg); do
  ifup $i
done

# Clean up stale NTP processes. This is because of BUG https://bugs.launchpad.net/ubuntu/+source/ntp/+bug/1125726
pkill lockfile-create || true

# Set the forward rule
if ! grep -q '^net.ipv4.ip_forward' /etc/sysctl.conf; then
  sysctl -w net.ipv4.ip_forward=1 | tee -a /etc/sysctl.conf
fi

# Add rules from the INPUT chain
iptables_general_rule_add 'INPUT -i br-dhcp -p udp --dport 67 -j ACCEPT'
iptables_general_rule_add 'INPUT -i br-dhcp -p tcp --dport 67 -j ACCEPT'
iptables_general_rule_add 'INPUT -i br-dhcp -p udp --dport 53 -j ACCEPT'
iptables_general_rule_add 'INPUT -i br-dhcp -p tcp --dport 53 -j ACCEPT'

# Add rules from the FORWARDING chain
iptables_general_rule_add 'FORWARD -i br-dhcp -j ACCEPT'
iptables_general_rule_add 'FORWARD -o br-dhcp -j ACCEPT'

# Add rules from the nat POSTROUTING chain
iptables_filter_rule_add nat 'POSTROUTING -s 10.0.0.0/24 ! -d 10.0.0.0/24 -j MASQUERADE'

# To provide internet connectivity to instances
iptables_filter_rule_add nat "POSTROUTING -o $(ip route get 1 | awk '/dev/ {print $5}') -j MASQUERADE"

# Add rules from the mangle POSTROUTING chain
iptables_filter_rule_add mangle 'POSTROUTING -s 10.0.0.0/24 -o br-dhcp -p udp -m udp --dport 68 -j CHECKSUM --checksum-fill'

# To ensure ssh checksum are always correct
iptables_filter_rule_add mangle 'POSTROUTING -p tcp -j CHECKSUM --checksum-fill'

# Enable partitioning of the "${DATA_DISK_DEVICE}"
PARTITION_HOST=${PARTITION_HOST:-true}
if [[ "${PARTITION_HOST}" = true ]]; then
  # Set the data disk device, if unset the largest unpartitioned device will be used to for host VMs
  DATA_DISK_DEVICE="${DATA_DISK_DEVICE:-$(lsblk -brndo NAME,TYPE,FSTYPE,RO,SIZE | awk '/d[b-z]+ disk +0/{ if ($4>m){m=$4; d=$1}}; END{print d}')}"
  parted --script /dev/${DATA_DISK_DEVICE} mklabel gpt
  parted --align optimal --script /dev/${DATA_DISK_DEVICE} mkpart kvm ext4 0% 100%
  mkfs.ext4 /dev/${DATA_DISK_DEVICE}1
  if ! grep -qw "^/dev/${DATA_DISK_DEVICE}1" /etc/fstab; then
    echo "/dev/${DATA_DISK_DEVICE}1 /var/lib/libvirt/images/ ext4 defaults 0 0" >> /etc/fstab
  fi
  mount -a
fi
