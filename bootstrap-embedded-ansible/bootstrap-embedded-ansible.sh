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

# Check if embedded ansible is already activated. If it is active, deactivate it.
(alias deactivate &> /dev/null && deactivate) || true

export OPTS=()
export CLONE_DIR="$(dirname $(readlink -f ${BASH_SOURCE[0]}))"
OPTS+=('CLONE_DIR')

export ANSIBLE_VERSION="${ANSIBLE_VERSION:-2.10.5}"
OPTS+=('ANSIBLE_VERSION')

export ANSIBLE_EMBED_HOME="${HOME}/ansible_venv"
OPTS+=('ANSIBLE_EMBED_HOME')

export ANSIBLE_ROLE_REQUIREMENTS="${ANSIBLE_ROLE_REQUIREMENTS:-$CLONE_DIR/ansible-requirements.yml}"
OPTS+=('ANSIBLE_ROLE_REQUIREMENTS')

export ANSIBLE_PYTHON_REQUIREMENTS="${ANSIBLE_PYTHON_REQUIREMENTS:-${CLONE_DIR}/python-requirements.txt}"
OPTS+=('ANSIBLE_PYTHON_REQUIREMENTS')

source /etc/os-release
export ID="$(echo ${ID} | awk -F'-' '{print $1}')"

if [[ ! -e "${ANSIBLE_EMBED_HOME}/bin/ansible" ]]; then
  if [  ${ID} = "ubuntu" ]; then
    apt-get update
    apt-get -y install virtualenv
  elif [  ${ID} = "opensuse" ] || [ ${ID} = "suse" ]; then
    zypper install -y insserv
    zypper install -y python-virtualenv
  elif [ ${ID} = "centos" ] || [ ${ID} = "redhat" ] || [ ${ID} = "rhel" ]; then
    yum install -y python3-virtualenv
  else
    echo "Unknown operating system"
    exit 99
  fi
  echo "done installing python-virtualenv"
  if [[ -f "/usr/bin/python3" ]]; then
    virtualenv --system-site-packages --python="/usr/bin/python3" "${ANSIBLE_EMBED_HOME}"
  elif [[ -f "/usr/bin/python2" ]]; then
    virtualenv --system-site-packages --python="/usr/bin/python2" "${ANSIBLE_EMBED_HOME}"
  else
    virtualenv "${ANSIBLE_EMBED_HOME}"
  fi
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade --force pip"
  echo "Ansible can be found here: ${ANSIBLE_EMBED_HOME}/bin"
fi

# Run ansible setup
eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade ansible=='${ANSIBLE_VERSION}' --isolated"
eval "${ANSIBLE_EMBED_HOME}/bin/ansible-galaxy install --force --role-file='${ANSIBLE_ROLE_REQUIREMENTS}' --roles-path='${ANSIBLE_EMBED_HOME}/repositories/roles'"
eval "${ANSIBLE_EMBED_HOME}/bin/ansible-playbook -i 'localhost,' '${CLONE_DIR}/embedded-ansible-setup.yml' -e 'ansible_venv_path=${ANSIBLE_EMBED_HOME}' -e 'ansible_python_requirement_file=${ANSIBLE_PYTHON_REQUIREMENTS}'"

if [[ -f "/etc/openstack_deploy/openstack_inventory.json" ]]; then
  export USER_VARS="$(for i in $(ls -1 /etc/openstack_deploy/user_*secret*.yml); do echo -n "-e@$i "; done)"
  OPTS+=('USER_VARS')
  echo "env USER_VARS set"

  export USER_ALL_VARS="$(for i in $(ls -1 /etc/openstack_deploy/user_*.yml); do echo -n "-e@$i "; done)"
  OPTS+=('USER_ALL_VARS')
  echo "env USER_ALL_VARS set"

  echo "Extra users variables can be expanded by including the option \$USER_VARS or \$USER_ALL_VARS on a playbook run."

  export ANSIBLE_INVENTORY="${ANSIBLE_EMBED_HOME}/inventory/openstack_inventory.sh"
  OPTS+=('ANSIBLE_INVENTORY')
  echo "env ANSIBLE_INVENTORY set"
fi

export ANSIBLE_HOST_KEY_CHECKING="False"
OPTS+=('ANSIBLE_HOST_KEY_CHECKING')
echo "env ANSIBLE_HOST_KEY_CHECKING set"

export ANSIBLE_ROLES_PATH="${ANSIBLE_EMBED_HOME}/repositories/roles"
OPTS+=('ANSIBLE_ROLES_PATH')
echo "env ANSIBLE_ROLES_PATH set"

export ANSIBLE_ACTION_PLUGINS="${ANSIBLE_EMBED_HOME}/repositories/roles/config_template/action"
OPTS+=('ANSIBLE_ACTION_PLUGINS')
echo "env ANSIBLE_ACTION_PLUGINS set"

export ANSIBLE_CONNECTION_PLUGINS="${ANSIBLE_EMBED_HOME}/repositories/roles/plugins/connection"
OPTS+=('ANSIBLE_CONNECTION_PLUGINS')
echo "env ANSIBLE_CONNECTION_PLUGINS set"

export ANSIBLE_STRATEGY_PLUGINS="${ANSIBLE_EMBED_HOME}/repositories/roles/plugins/strategy"
OPTS+=('ANSIBLE_STRATEGY_PLUGINS')
echo "env ANSIBLE_STRATEGY_PLUGINS set"

export ANSIBLE_TRANSPORT="${ANSIBLE_TRANSPORT:-ssh}"
OPTS+=('ANSIBLE_TRANSPORT')
echo "env ANSIBLE_TRANSPORT set"

export ANSIBLE_SSH_PIPELINING="${ANSIBLE_SSH_PIPELINING:-True}"
OPTS+=('ANSIBLE_SSH_PIPELINING')
echo "env ANSIBLE_SSH_PIPELINING set"

export ANSIBLE_PIPELINING="${ANSIBLE_SSH_PIPELINING}"
OPTS+=('ANSIBLE_PIPELINING')
echo "env ANSIBLE_PIPELINING set"

export ANSIBLE_SSH_RETRIES="${ANSIBLE_SSH_RETRIES:-5}"
OPTS+=('ANSIBLE_SSH_RETRIES')
echo "env ANSIBLE_SSH_RETRIES set"

source ${ANSIBLE_EMBED_HOME}/bin/activate
echo "Embedded Ansible has been activated. Run 'deactivate' to leave the embedded environment".

function deactivate_embedded_venv {
  deactivate
  for i in ${OPTS[@]}; do
    unset ${i}
  done
  unset deactivate_embedded_venv
  unalias deactivate
}

alias deactivate=deactivate_embedded_venv
