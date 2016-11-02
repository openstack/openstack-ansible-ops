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

MAX_RETRIES=${MAX_RETRIES:-5}

# Load all functions
source functions.rc

# Reset the ssh-agent service to remove potential key issues
ssh_agent_reset

# Install git and tmux for use within the OSA deploy
apt-get install -y git tmux

# Clone the OSA source code
git clone https://git.openstack.org/openstack/openstack-ansible /opt/openstack-ansible || true

# Ensure the "/etc/openstack_deploy" exists
mkdir_check "/etc/openstack_deploy"

pushd /opt/openstack-ansible/
  # Fetch all current refs
  git fetch --all

  # Checkout the OpenStack-Ansible branch
  git checkout "${OSA_BRANCH:-master}"

  # Copy the etc files into place
  cp -vR etc/openstack_deploy/* /etc/openstack_deploy/
popd

# Create a secondary static inventory for hosts
ansible_static_inventory "/opt/ansible-static-inventory.ini"

# Create the OpenStack User Config
HOSTIP="$(ip route get 1 | awk '{print $NF;exit}')"
sed "s/__HOSTIP__/${HOSTIP}/g" templates/openstack_user_config.yml > /etc/openstack_deploy/openstack_user_config.yml

# Create the swift config: function group_name host_type
cp -v templates/osa-swift.yml /etc/openstack_deploy/conf.d/swift.yml


### =========== WRITE OF conf.d FILES =========== ###
# Setup cinder hosts: function group_name host_type
write_osa_general_confd storage-infra_hosts cinder
write_osa_cinder_confd storage_hosts cinder

# Setup nova hosts: function group_name host_type
write_osa_general_confd compute_hosts nova_compute

# Setup infra hosts: function group_name host_type
write_osa_general_confd identity_hosts infra
write_osa_general_confd repo-infra_hosts infra
write_osa_general_confd os-infra_hosts infra
write_osa_general_confd shared-infra_hosts infra

# Setup logging hosts: function group_name host_type
write_osa_general_confd log_hosts logging

# Setup network hosts: function group_name host_type
write_osa_general_confd network_hosts infra

# Setup swift hosts: function group_name host_type
write_osa_swift_proxy_confd swift-proxy_hosts swift
write_osa_swift_storage_confd swift_hosts swift
### =========== END WRITE OF conf.d FILES =========== ###

# Enable pre-config the OSA enviroment for deploying OSA.
PRE_CONFIG_OSA=${PRE_CONFIG_OSA:-true}
if [[ "${PRE_CONFIG_OSA}" = true ]]; then
  pushd /opt/openstack-ansible/
    # Bootstrap ansible into the environment
    bash ./scripts/bootstrap-ansible.sh

    # Generate the passwords for the environment
    python ./scripts/pw-token-gen.py --file /etc/openstack_deploy/user_secrets.yml

    # This is happening so the VMs running the infra use less storage
    osa_user_var_add lxc_container_backing_store 'lxc_container_backing_store: dir'

    # Tempest is being configured to use a known network
    osa_user_var_add tempest_public_subnet_cidr 'tempest_public_subnet_cidr: 172.29.248.0/22'

    # This makes running neutron in a distributed system easier and a lot less noisy
    osa_user_var_add neutron_l2_population 'neutron_l2_population: True'

    # This makes the glance image store use swift instead of the file backend
    osa_user_var_add glance_default_store 'glance_default_store: swift'
  popd
fi

# Enable deploy OSA of the "${RUN_OSA}"
RUN_OSA=${RUN_OSA:-true}
if [[ "${RUN_OSA}" = true ]]; then
  # Set the number of forks for the ansible client calls
  export ANSIBLE_FORKS=${ANSIBLE_FORKS:-15}

  pushd /opt/openstack-ansible
    export DEPLOY_AIO=true
    bash ./scripts/run-playbooks.sh
  popd

  EXEC_DIR="$(pwd)"
  pushd /opt/openstack-ansible/playbooks
    if [[ -f "/usr/local/bin/openstack-ansible.rc" ]]; then
      source /usr/local/bin/openstack-ansible.rc
    fi
    ansible -m script -a "${EXEC_DIR}/openstack-service-setup.sh" 'utility_all[0]'
  popd
fi
