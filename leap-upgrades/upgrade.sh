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

### Kilo System migration
# Run tasks
UPGRADE_SCRIPTS="${UPGRADE_UTILS}-kilo/scripts"
# If the kilo leap has been accomplished, skip.
if [[ ! -f "/opt/leap42/openstack-ansible-${KILO_RELEASE}.leap" ]] && [[ "${UPGRADES_TO_TODOLIST}" =~ .*KILO.* ]]; then
  notice 'Leaping to Kilo'
  link_release "/opt/leap42/openstack-ansible-${KILO_RELEASE}"
  pushd "/opt/leap42/openstack-ansible-${KILO_RELEASE}"
    if [[ -d "/etc/rpc_deploy" ]]; then
      SCRIPTS_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}/scripts" MAIN_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}" ${UPGRADE_SCRIPTS}/create-new-openstack-deploy-structure.sh
    fi
    ${UPGRADE_SCRIPTS}/juno-rpc-extras-create.py
    SCRIPTS_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}/scripts" MAIN_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}" ${UPGRADE_SCRIPTS}/new-variable-prep.sh
    # Convert LDAP variables if any are found
    if grep '^keystone_ldap.*' /etc/openstack_deploy/user_variables.yml;then
      ${UPGRADE_SCRIPTS}/juno-kilo-ldap-conversion.py
    fi
    # Create the repo servers entries from the same entries found within the infra_hosts group.
    if ! grep -r '^repo-infra_hosts\:' /etc/openstack_deploy/openstack_user_config.yml /etc/openstack_deploy/conf.d/;then
      if [ ! -f "/etc/openstack_deploy/conf.d/repo-servers.yml" ];then
        ${UPGRADE_SCRIPTS}/juno-kilo-add-repo-infra.py
      fi
    fi
    # In Kilo+ we need to mark the network used for container ssh and management.
    if ! grep -q "is_container_address" /etc/openstack_deploy/openstack_user_config.yml; then
      sed -i.bak '/container_bridge: "br-mgmt"/a \ \ \ \ \ \ \ \ is_container_address: true' /etc/openstack_deploy/openstack_user_config.yml
    fi
    if ! grep -q "is_ssh_address" /etc/openstack_deploy/openstack_user_config.yml; then
      sed -i.bak '/container_bridge: "br-mgmt"/a \ \ \ \ \ \ \ \ is_ssh_address: true' /etc/openstack_deploy/openstack_user_config.yml
    fi
    ${UPGRADE_SCRIPTS}/juno-is-metal-preserve.py
    SCRIPTS_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}/scripts" MAIN_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}" ${UPGRADE_SCRIPTS}/old-variable-remove.sh
    SCRIPTS_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}/scripts" MAIN_PATH="/opt/leap42/openstack-ansible-${KILO_RELEASE}" ${UPGRADE_SCRIPTS}/juno-container-cleanup.sh
  popd
  UPGRADE_PLAYBOOKS="${UPGRADE_UTILS}-kilo/playbooks"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/user-secrets-adjustments-kilo.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${KILO_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/host-adjustments.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/remove-juno-log-rotate.yml || true")
  if [ "${SKIP_SWIFT_UPGRADE}" != "yes" ]; then
    if [ "$(ansible 'swift_hosts' --list-hosts)" != "No hosts matched" ]; then
      RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/swift-ring-adjustments.yml")
      RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/swift-repo-adjustments.yml")
    fi
  fi
  run_items "/opt/leap42/openstack-ansible-${KILO_RELEASE}"
  tag_leap_success "${KILO_RELEASE}-prep"
fi
### Kilo System migration

### Liberty System migration
# Run tasks
if [[ ! -f "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}.leap" ]] && [[ "${UPGRADES_TO_TODOLIST}" =~ .*LIBERTY.*  ]]; then
  notice 'Leaping to liberty'
  link_release "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}"
  UPGRADE_PLAYBOOKS="${UPGRADE_UTILS}-liberty/playbooks"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/ansible_fact_cleanup-liberty.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/deploy-config-changes-liberty.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/user-secrets-adjustment-liberty.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/mariadb-apt-cleanup.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/disable-neutron-port-security.yml")
  run_items "/opt/leap42/openstack-ansible-${LIBERTY_RELEASE}"
  tag_leap_success "${LIBERTY_RELEASE}-prep"
fi
### Liberty System migration

### Mitaka System migration
# Run tasks
if [[ ! -f "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}.leap" ]] && [[ "${UPGRADES_TO_TODOLIST}" =~ .*MITAKA.* ]]; then
  notice 'Leaping to Mitaka'
  link_release "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}"
  UPGRADE_PLAYBOOKS="${UPGRADE_UTILS}-mitaka/playbooks"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/ansible_fact_cleanup-mitaka-1.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/deploy-config-changes-mitaka.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${MITAKA_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/user-secrets-adjustment-mitaka.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${MITAKA_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/pip-conf-removal.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/old-hostname-compatibility-mitaka.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/ansible_fact_cleanup-mitaka-2.yml")
  run_items "/opt/leap42/openstack-ansible-${MITAKA_RELEASE}"
  tag_leap_success "${MITAKA_RELEASE}-prep"
fi
### Mitaka System migration

### Newton Deploy
# Run tasks
if [[ ! -f "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}.leap" ]] && [[ "${UPGRADES_TO_TODOLIST}" =~ .*NEWTON*  ]]; then
  notice 'Running newton leap'
  link_release "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
  UPGRADE_PLAYBOOKS="${UPGRADE_UTILS}-newton/playbooks"
  RUN_TASKS=()
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/lbaas-version-check.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/ansible_fact_cleanup-newton.yml")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/deploy-config-changes-newton.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${NEWTON_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/user-secrets-adjustment-newton.yml -e 'osa_playbook_dir=/opt/leap42/openstack-ansible-${NEWTON_RELEASE}'")
  RUN_TASKS+=("${UPGRADE_PLAYBOOKS}/old-hostname-compatibility-newton.yml")
  run_items "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
  tag_leap_success "${NEWTON_RELEASE}-prep"
fi

### Run host upgrade
if [[ ! -f "/opt/leap42/openstack-ansible-upgrade-hostupgrade.leap" ]]; then
    notice 'Running host upgrade'
    link_release "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
    RUN_TASKS=()
    RUN_TASKS+=("${UPGRADE_UTILS}/pip-conf-purge.yml")
    RUN_TASKS+=("${UPGRADE_UTILS}/mariadb-repo-cleanup.yml")
    RUN_TASKS+=("openstack-hosts-setup.yml")
    run_items "${REDEPLOY_OA_FOLDER}"
    tag_leap_success "upgrade-hostupgrade"
fi
