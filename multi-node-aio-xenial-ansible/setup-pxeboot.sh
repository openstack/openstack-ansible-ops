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

# Use Ansible to install and configure a DHCP server, TFTP server and Apache
# so we can PXEboot all the VMs
ansible-playbook -v -i inventory create_pxeboot_server.yml --extra-vars \
          "vm_disk_device=${DEVICE_NAME} ssh_key=\"${SSHKEY}\" vm_net_iface=${DEFAULT_NETWORK}"
sed -i 's/^INTERFACES.*/INTERFACES="br-dhcp"/g' /etc/default/isc-dhcp-server

# Ensure the services are (re)started
service isc-dhcp-server restart
service atftpd restart

# Create a xenial sources file for the VMs to download
cp -v templates/xenial-sources.list /var/www/html/xenial-sources.list
