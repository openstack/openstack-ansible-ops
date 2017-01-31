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

# NOTICE: To run this in an automated fashion run the script via
#   root@HOSTNAME:/opt/openstack-ansible# echo "YES" | bash scripts/run-upgrade.sh

## Shell Opts ----------------------------------------------------------------
set -e -u -v

## Main ----------------------------------------------------------------------
source lib/vars.sh
source lib/functions.sh

# Execute a preflight check
pre_flight

# Clone the Juno release so we have a clean copy of the source code.
if [[ ! -f "/opt/leap42/openstack-ansible-${JUNO_RELEASE}-prep.leap" ]]; then
  clone_release ${JUNO_RELEASE}
  touch "/opt/leap42/openstack-ansible-${JUNO_RELEASE}-prep.leap"
fi

# Build the releases. This will clone all of the releases and check them out
#  separately in addition to creating all of the venvs needed for a successful migration.
if [[ ! -f "/opt/leap42/openstack-ansible-${KILO_RELEASE}-prep.leap" ]]; then
  clone_release ${KILO_RELEASE}
  get_venv ${KILO_RELEASE}
  touch "/opt/leap42/openstack-ansible-${KILO_RELEASE}-prep.leap"
fi

if [[ ! -f "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}-prep.leap" ]]; then
  clone_release ${LIBERTY_RELEASE}
  get_venv ${LIBERTY_RELEASE}
  touch "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}-prep.leap"
fi

if [[ ! -f "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}-prep.leap" ]]; then
  clone_release ${MITAKA_RELEASE}
  get_venv ${MITAKA_RELEASE}
  touch "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}-prep.leap"
fi

if [[ ! -f "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}-prep.leap" ]]; then
  clone_release ${NEWTON_RELEASE}
  get_venv ${NEWTON_RELEASE}
  touch "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}-prep.leap"
fi

RUN_TASKS=()
RUN_TASKS+=("${UPGRADE_UTILS}/cinder-volume-container-lvm-check.yml")
RUN_TASKS+=("${UPGRADE_UTILS}/db-backup.yml")

if [[ -d "/etc/rpc_deploy" ]]; then
  RELEASE="${JUNO_RELEASE}"
  export ANSIBLE_INVENTORY="/opt/leap42/openstack-ansible-${RELEASE}/rpc_deployment/inventory"
else
  RELEASE="${NEWTON_RELEASE}"
  export ANSIBLE_INVENTORY="/opt/leap42/openstack-ansible-${RELEASE}/playbooks/inventory"
fi

# temp upgrade ansible is used to ensure 1.9.x compat.
PS1="\\u@\h \\W]\\$" . "/opt/ansible-runtime/bin/activate"
run_items "/opt/leap42/openstack-ansible-${RELEASE}"
deactivate
unset ANSIBLE_INVENTORY

link_release "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
system_bootstrap "/opt/openstack-ansible"
