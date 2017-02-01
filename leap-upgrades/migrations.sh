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

### Run the DB migrations
# Stop the services to ensure DB and application consistency
if [[ ! -f "/opt/leap42/openstack-ansible-poweroff.leap" ]]; then
  if [ -e "/opt/openstack-ansible" ]; then
    link_release "/opt/leap42/openstack-ansible-${KILO_RELEASE}"
  fi
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_UTILS}/power-down.yml")
  run_items "/opt/openstack-ansible"
  tag_leap_success "poweroff"
fi

# Kilo migrations
if [[ ! -f "/opt/leap42/openstack-ansible-${KILO_RELEASE}-db.leap" ]]; then
  notice "Running Kilo DB Migrations"
  link_release "/opt/leap42/openstack-ansible-${KILO_RELEASE}"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-kilo.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${KILO_RELEASE}.tgz'")
  run_items "/opt/leap42/openstack-ansible-${KILO_RELEASE}"
  tag_leap_success "${KILO_RELEASE}-db"
fi

# Liberty migrations
if [[ ! -f "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}-db.leap" ]]; then
  notice "Running Liberty DB Migrations"
  link_release "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-liberty.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${LIBERTY_RELEASE}.tgz'")
  RUN_TASKS+=("${UPGRADE_UTILS}/glance-db-storage-url-fix.yml")
  run_items "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}"
  tag_leap_success "${LIBERTY_RELEASE}-db"
fi

# Mitaka migrations
if [[ ! -f "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}-db.leap" ]]; then
  notice "Running Mitaka DB Migrations"
  link_release "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-mitaka.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${MITAKA_RELEASE}.tgz'")
  RUN_TASKS+=("${UPGRADE_UTILS}/neutron-mtu-migration.yml")
  run_items "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}"
  tag_leap_success "${MITAKA_RELEASE}-db"
fi

# Newton migrations
if [[ ! -f "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}-db.leap" ]]; then
  notice "Running Newton DB Migrations"
  link_release "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_UTILS}/db-collation-alter.yml")
  RUN_TASKS+=("${UPGRADE_UTILS}/db-migrations-newton.yml -e 'venv_tar_location=/opt/leap42/venvs/openstack-ansible-${NEWTON_RELEASE}.tgz'")
  run_items "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
  tag_leap_success "${NEWTON_RELEASE}-db"
fi
### Run the DB migrations
