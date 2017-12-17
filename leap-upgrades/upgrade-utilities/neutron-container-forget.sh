#!/usr/bin/env bash

# Copyright 2017, Rackspace US, Inc.
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

## Shell Opts ----------------------------------------------------------------
set -e -u -v

export MAIN_PATH="${MAIN_PATH:-$(dirname $(dirname $(dirname $(dirname $(readlink -f $0)))))}"
export SCRIPTS_PATH="${SCRIPTS_PATH:-$(dirname $(dirname $(dirname $(readlink -f $0))))}"

function remove_inv_items {
  ${SCRIPTS_PATH}/inventory-manage.py -f /etc/openstack_deploy/openstack_inventory.json -r "$1"
}

function get_inv_items {
  ${SCRIPTS_PATH}/inventory-manage.py -f /etc/openstack_deploy/openstack_inventory.json -l | grep -w ".*$1"
}

# Remove containers that we no longer need
pushd ${MAIN_PATH}/playbooks

  # Remove the dead container types from inventory
  REMOVED_CONTAINERS=""
  REMOVED_CONTAINERS+="$(get_inv_items 'neutron_agent' | awk '{print $2}') "
  RESERVED_IPS=""
  RESERVED_IPS+="$(get_inv_items 'neutron_agent' | awk '{print $12}') "

  for ips in ${RESERVED_IPS}; do
    echo "$ips" >> /etc/openstack_deploy/leapfrog_old_ips_reservation
    sed -i "/^used_ips:/a \ \ - $ips" /etc/openstack_deploy/openstack_user_config.yml
  done
  for i in ${REMOVED_CONTAINERS};do
    echo "$i" >> /etc/openstack_deploy/leapfrog_remove_remaining_old_containers
    remove_inv_items $i
  done

popd
