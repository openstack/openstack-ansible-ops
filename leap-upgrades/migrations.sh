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

## Ensure UPGRADES_TO_TODOLIST is set
check_for_todolist

## Ensure RELEASE is set
check_for_release

### Run the DB migrations
# Stop the services to ensure DB and application consistency
if [[ ! -f "/opt/leap42/openstack-ansible-poweroff.leap" ]]; then
  if [ -e "/opt/openstack-ansible" ]; then
    link_release "/opt/leap42/openstack-ansible-${RELEASE}"
  fi
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_UTILS}/power-down.yml")
  # This run_items doesn't care about which folder it runs in, because just
  # one task is used, and it's not in the folder
  run_items "${REDEPLOY_OA_FOLDER}"
  tag_leap_success "poweroff"
fi

# Run Migrations for Each Release in the TODO
for RELEASES in ${UPGRADES_TO_TODOLIST}; do
  RELEASE_NAME=${RELEASES}_RELEASE
  if [[ ! -f "/opt/leap42/openstack-ansible-${!RELEASE_NAME}-db.leap" ]]; then
    notice "Running ${RELEASES} DB Migrations"
    link_release "/opt/leap42/openstack-ansible-${!RELEASE_NAME}"
    RUN_TASKS=()
    if [[ "${RELEASES}" == "JUNO" ]]; then
      RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-kilo.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${!RELEASE_NAME}.tgz'")
    elif [[ "${RELEASES}" == "LIBERTY" ]]; then
      RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-liberty.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${!RELEASE_NAME}.tgz'")
      RUN_TASKS+=("${UPGRADE_UTILS}/glance-db-storage-url-fix.yml")
    elif [[ "${RELEASES}" == "MITAKA" ]]; then
      RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-mitaka.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${!RELEASE_NAME}.tgz'")
      RUN_TASKS+=("${UPGRADE_UTILS}/neutron-mtu-migration.yml")
    elif [[ "${RELEASES}" == "NEWTON" ]]; then
      RUN_TASKS+=("${UPGRADE_UTILS}/db-collation-alter.yml")
      RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-newton.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${!RELEASE_NAME}.tgz'")
    fi
    run_items "/opt/leap42/openstack-ansible-${!RELEASE_NAME}"
    tag_leap_success "${!RELEASE_NAME}-db"
  fi
done
