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

### Set lock file to notate redeploy has started
# Notate that redeploy has started, if it fails midway, it can be
# resumed from the starting script without getting prompted to
# set the version again.
touch /etc/openstack_deploy/upgrade-leap/redeploy-started.complete

### Run the redeploy tasks
# Forget about the old neutron agent container in inventory.
#  This is done to maximize uptime by leaving the old systems in
#  place while the redeployment work is going on.
# TODO(evrardjp): Move this to a playbook, this way it will follow the
# RUN_TASKS model

if [ ! -f /etc/openstack_deploy/upgrade-leap/neutron-container-forget.complete ];then
  SCRIPTS_PATH="/opt/leap42/openstack-ansible-${NEWTON_RELEASE}/scripts" \
    MAIN_PATH="/opt/leap42/openstack-ansible-${NEWTON_RELEASE}" \
      ${UPGRADE_UTILS}/neutron-container-forget.sh
  touch /etc/openstack_deploy/upgrade-leap/neutron-container-forget.complete
fi

link_release "/opt/leap42/openstack-ansible-${NEWTON_RELEASE}"
RUN_TASKS=()

# Pre-setup-hosts hook
if [[ -n ${PRE_SETUP_HOSTS_HOOK+x} ]]; then
  RUN_TASKS+=("$PRE_SETUP_HOSTS_HOOK")
fi

# Setup Hosts
RUN_TASKS+=("openstack-hosts-setup.yml -e redeploy_rerun=true")

# Ensure the same pip everywhere, even if requirement met or above
RUN_TASKS+=("${UPGRADE_UTILS}/pip-unify.yml -e release_version=\"${NEWTON_RELEASE}\"")

RUN_TASKS+=("${UPGRADE_UTILS}/db-stop.yml")
RUN_TASKS+=("${UPGRADE_UTILS}/ansible_fact_cleanup.yml")
# Physical host cleanup
RUN_TASKS+=("${UPGRADE_UTILS}/destroy-old-containers.yml -e 'destroy_hosts='${CONTAINERS_TO_DESTROY}''")
# Permissions for qemu save, because physical host cleanup
RUN_TASKS+=("${UPGRADE_UTILS}/nova-libvirt-fix.yml")

RUN_TASKS+=("lxc-hosts-setup.yml")
RUN_TASKS+=("lxc-containers-create.yml")

# Post-setup-hosts hook
if [[ -n ${POST_SETUP_HOSTS_HOOK+x} ]]; then
  RUN_TASKS+=("$POST_SETUP_HOSTS_HOOK")
fi

# Pre-setup-infrastructure hook
if [[ -n ${PRE_SETUP_INFRASTRUCTURE_HOOK+x} ]]; then
  RUN_TASKS+=("$PRE_SETUP_INFRASTRUCTURE_HOOK")
fi

# Setup Infrastructure
RUN_TASKS+=("unbound-install.yml")
RUN_TASKS+=("repo-install.yml")
RUN_TASKS+=("${UPGRADE_UTILS}/haproxy-cleanup.yml")
RUN_TASKS+=("haproxy-install.yml")
RUN_TASKS+=("memcached-install.yml")
RUN_TASKS+=("galera-install.yml")
RUN_TASKS+=("rabbitmq-install.yml")
RUN_TASKS+=("etcd-install.yml")
RUN_TASKS+=("utility-install.yml")
RUN_TASKS+=("rsyslog-install.yml")

# MariaDB sync for major maria upgrades and cluster schema sync
RUN_TASKS+=("${UPGRADE_UTILS}/db-force-upgrade.yml")

# Post-setup-infrastructure hook
if [[ -n ${POST_SETUP_INFRASTRUCTURE_HOOK+x} ]]; then
  RUN_TASKS+=("$POST_SETUP_INFRASTRUCTURE_HOOK")
fi

# Pre-setup-openstack hook
if [[ -n ${PRE_SETUP_OPENSTACK_HOOK+x} ]]; then
  RUN_TASKS+=("$PRE_SETUP_OPENSTACK_HOOK")
fi

# Setup OpenStack

RUN_TASKS+=("os-keystone-install.yml")
RUN_TASKS+=("os-glance-install.yml")
RUN_TASKS+=("os-cinder-install.yml")


# The first run will install everything everywhere and restart the nova services
RUN_TASKS+=("os-nova-install.yml")

# This is being run before hand to ensure a speedy service upgrade to maintain running VMs.
#  this also works around an issue where very early versions of libvirt may not be fully
#  replaced on the first run.
RUN_TASKS+=("os-nova-install.yml --limit nova_compute")

RUN_TASKS+=("os-neutron-install.yml")
RUN_TASKS+=("${UPGRADE_UTILS}/neutron-remove-old-containers.yml")

RUN_TASKS+=("os-heat-install.yml")
RUN_TASKS+=("os-horizon-install.yml")
RUN_TASKS+=("os-ceilometer-install.yml")
RUN_TASKS+=("os-aodh-install.yml")

if grep -rni "^gnocchi_storage_driver" /etc/openstack_deploy/*.{yaml,yml} | grep -qw "swift"; then
  RUN_TASKS+=("os-gnocchi-install.yml -e gnocchi_identity_only=true")
fi

if [ "${SKIP_SWIFT_UPGRADE}" != "yes" ]; then
  RUN_TASKS+=("os-swift-install.yml")
fi

RUN_TASKS+=("os-gnocchi-install.yml")
RUN_TASKS+=("os-ironic-install.yml")
RUN_TASKS+=("os-magnum-install.yml")
RUN_TASKS+=("os-sahara-install.yml")

RUN_TASKS+=("${UPGRADE_UTILS}/post-redeploy-cleanup.yml")

# Post-setup-openstack hook
if [[ -n ${POST_SETUP_OPENSTACK_HOOK+x} ]]; then
  RUN_TASKS+=("$POST_SETUP_OPENSTACK_HOOK")
fi

# Loads a shell script that can be used to modify
# the RUN_TASKS behavior.
if [[ ${REDEPLOY_EXTRA_SCRIPT:-} ]]; then
    notice "Running extra script before re-deploy"
    source ${REDEPLOY_EXTRA_SCRIPT}
fi
run_items "${REDEPLOY_OA_FOLDER}"
### Run the redeploy tasks
