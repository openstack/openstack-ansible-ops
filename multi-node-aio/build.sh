#!/usr/bin/env bash
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

set -euvo

source bootstrap.sh

source ansible-env.rc

ansible mnaio_hosts \
        -i ${MNAIO_INVENTORY:-"playbooks/inventory"} \
        -m pip \
        -a "name=netaddr"

ansible-playbook -vv \
                 -i ${MNAIO_INVENTORY:-"playbooks/inventory"} \
                 -e setup_host=${SETUP_HOST:-"true"} \
                 -e setup_pxeboot=${SETUP_PXEBOOT:-"true"} \
                 -e setup_dhcpd=${SETUP_DHCPD:-"true"} \
                 -e deploy_vms=${DEPLOY_VMS:-"true"} \
                 -e deploy_osa=${DEPLOY_OSA:-"true"} \
                 -e osa_branch=${OSA_BRANCH:-"master"} \
                 -e default_network=${DEFAULT_NETWORK:-"eth0"} \
                 -e default_image=${DEFAULT_IMAGE:-"ubuntu-16.04-amd64"} \
                 -e vm_disk_size=${VM_DISK_SIZE:-92160} \
                 -e http_proxy=${http_proxy:-''} \
                 -e run_osa=${RUN_OSA:-"true"} \
                 -e pre_config_osa=${PRE_CONFIG_OSA:-"true"} \
                 -e configure_openstack=${CONFIGURE_OPENSTACK:-"true"} \
                 -e config_prerouting=${CONFIG_PREROUTING:-"false"} \
                 -e default_ubuntu_kernel=${DEFAULT_KERNEL:-"linux-image-generic"} \
                 --force-handlers \
                 playbooks/site.yml
