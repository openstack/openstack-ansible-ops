#!/usr/bin/env bash
# Copyright 2018, Rackspace US, Inc.
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

export ANSIBLE_EMBED_HOME="${HOME}/ansible25"

if [[ ! -e "${ANSIBLE_EMBED_HOME}/bin/ansible" ]]; then
  apt-get update
  apt-get -y install python3-virtualenv python-virtualenv
  if [[ -f "/usr/bin/python2" ]]; then
    virtualenv --python="/usr/bin/python2" "${ANSIBLE_EMBED_HOME}"
  elif [[ -f "/usr/bin/python3" ]]; then
    virtualenv --python="/usr/bin/python3" "${ANSIBLE_EMBED_HOME}"
  else
    virtualenv "${ANSIBLE_EMBED_HOME}"
  fi
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade --force pip"
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade ansible==2.5.2.0 --isolated"
  echo "Ansible can be found here: ${ANSIBLE_EMBED_HOME}/bin"
fi

if [[ ! -d "${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template" ]]; then
  mkdir -p "${ANSIBLE_EMBED_HOME}/repositories"
  git clone https://git.openstack.org/openstack/ansible-config_template "${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template"
fi

if [[ ! -d "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_service" ]]; then
  mkdir -p "${ANSIBLE_EMBED_HOME}/repositories"
  git clone https://git.openstack.org/openstack/ansible-role-systemd_service "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_service"
fi

if [[ -f "/etc/openstack_deploy/openstack_inventory.json" ]]; then
  if [[ ! -f "${ANSIBLE_EMBED_HOME}/inventory/openstack_inventory.sh" ]]; then
    mkdir -p "${ANSIBLE_EMBED_HOME}/inventory"
    cat > "${ANSIBLE_EMBED_HOME}/inventory/openstack_inventory.sh" <<EOF
#!/usr/bin/env bash
cat /etc/openstack_deploy/openstack_inventory.json
EOF
    chmod +x "${ANSIBLE_EMBED_HOME}/inventory/openstack_inventory.sh"
  fi

  export USER_VARS="$(for i in $(ls -1 /etc/openstack_deploy/user_*secret*.yml); do echo -n "-e@$i "; done)"
  echo "env USER_VARS set"
  echo "Extra users variables can be expanded by including the option \$USER_VARS on a playbook run."

  export ANSIBLE_INVENTORY="${ANSIBLE_EMBED_HOME}/inventory/openstack_inventory.sh"
  echo "env ANSIBLE_INVENTORY set"
fi

export ANSIBLE_HOST_KEY_CHECKING="False"
echo "env ANSIBLE_HOST_KEY_CHECKING set"

export ANSIBLE_ROLES_PATH="${ANSIBLE_EMBED_HOME}/repositories/roles"
echo "env ANSIBLE_ACTION_PLUGINS set"

export ANSIBLE_ACTION_PLUGINS="${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template/action"
echo "env ANSIBLE_ROLES_PATH set"

source ${ANSIBLE_EMBED_HOME}/bin/activate
echo "Embedded Ansible has been activated. Run 'deactivate' to leave the embedded environment".
