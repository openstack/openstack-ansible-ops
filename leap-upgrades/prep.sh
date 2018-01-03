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
set -e -u

## Main ----------------------------------------------------------------------
source lib/vars.sh
source lib/functions.sh

# Execute a preflight check
pre_flight

# assemble list of versions to check out
TODO="${CODE_UPGRADE_FROM}"
TODO+=" ${UPGRADES_TO_TODOLIST}"

# Build the releases. This will loop through the TODO variable, check out the
# releases, and create all of the venvs needed for a successful migration
for RELEASES in ${TODO}; do
  RELEASE_NAME=${RELEASES}_RELEASE
  if [[ ! -f "/opt/leap42/openstack-ansible-${!RELEASE_NAME}-prep.leap" ]]; then
    clone_release ${!RELEASE_NAME}
    if [[ "${RELEASES}" != "JUNO" ]] || [[ "${RELEASES}" != "NEWTON" ]]; then
      get_venv ${!RELEASE_NAME}
    fi
    touch "/opt/leap42/openstack-ansible-${!RELEASE_NAME}-prep.leap"
  fi
done

if [[ ! -f "/opt/leap42/openstack-ansible-prep-finalsteps.leap" ]]; then
    RUN_TASKS=()

    RUN_TASKS+=("${UPGRADE_UTILS}/cinder-volume-container-lvm-check.yml")
    RUN_TASKS+=("${UPGRADE_UTILS}/db-backup.yml")

    # temp upgrade ansible is used to ensure 1.9.x compat.
    PS1="\\u@\h \\W]\\$" . "/opt/ansible-runtime/bin/activate"
    run_items "/opt/leap42/openstack-ansible-${RELEASE}"
    deactivate
    unset ANSIBLE_INVENTORY

    link_release "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
    bootstrap_recent_ansible
    touch "/opt/leap42/openstack-ansible-prep-finalsteps.leap"
fi
