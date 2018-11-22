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

export OPTS=()
export ANSIBLE_VERSION="${ANSIBLE_VERSION:-2.5.5.0}"
export ANSIBLE_EMBED_HOME="${HOME}/ansible_venv"
OPTS+=('ANSIBLE_EMBED_HOME')

source /etc/os-release
export ID="$(echo ${ID} | awk -F'-' '{print $1}')"

if [[ ! -e "${ANSIBLE_EMBED_HOME}/bin/ansible" ]]; then
  if [  ${ID} = "ubuntu" ]; then
    apt-get update
    apt-get -y install python-virtualenv
  elif [  ${ID} = "opensuse" ]; then
    zypper install -y python-virtualenv
  elif [ ${ID} = "centos" ] || [ ${ID} ="redhat" ]; then
    yum install -y python-virtualenv
  else
    echo "Unknown operating system"
    exit 99
  fi
  echo "done installing python-virtualenv"
  if [[ -f "/usr/bin/python2" ]]; then
    virtualenv --system-site-packages --python="/usr/bin/python2" "${ANSIBLE_EMBED_HOME}"
  elif [[ -f "/usr/bin/python3" ]]; then
    virtualenv --system-site-packages --python="/usr/bin/python3" "${ANSIBLE_EMBED_HOME}"
  else
    virtualenv "${ANSIBLE_EMBED_HOME}"
  fi
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade --force pip"
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade ansible==${ANSIBLE_VERSION} --isolated"
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade jmespath --isolated"
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade hvac --isolated"
  eval "${ANSIBLE_EMBED_HOME}/bin/pip install --upgrade netaddr --isolated"
  echo "Ansible can be found here: ${ANSIBLE_EMBED_HOME}/bin"
fi

if [[ ! -d "${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template" ]]; then
  mkdir -p "${ANSIBLE_EMBED_HOME}/repositories"
  git clone https://git.openstack.org/openstack/ansible-config_template "${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template"
  pushd "${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template"
    git checkout a5c9d97e18683f0fdf9769d94ba174c72e2d093c  # HEAD of master from 20-06-18
  popd
fi

if [[ ! -d "${ANSIBLE_EMBED_HOME}/repositories/openstack-ansible-plugins" ]]; then
  mkdir -p "${ANSIBLE_EMBED_HOME}/repositories"
  git clone https://git.openstack.org/openstack/openstack-ansible-plugins "${ANSIBLE_EMBED_HOME}/repositories/openstack-ansible-plugins"
  pushd "${ANSIBLE_EMBED_HOME}/repositories/openstack-ansible-plugins"
    git checkout cef7946b3b3b3e4d02406c228741985a94b72cff  # HEAD of master from 20-06-18
  popd
fi

if [[ ! -d "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_service" ]]; then
  mkdir -p "${ANSIBLE_EMBED_HOME}/repositories"
  git clone https://git.openstack.org/openstack/ansible-role-systemd_service "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_service"
  pushd "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_service"
    git checkout 02f5ff1c0e073af53bed2141a045e608162970ea  # HEAD of master from 20-06-18
  popd
fi

if [[ ! -d "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_mount" ]]; then
  mkdir -p "${ANSIBLE_EMBED_HOME}/repositories"
  git clone https://git.openstack.org/openstack/ansible-role-systemd_mount "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_mount"
  pushd "${ANSIBLE_EMBED_HOME}/repositories/roles/systemd_mount"
    git checkout 0cca0b06e20a4e3d2b6b4ca19172717b6b37b68a  # HEAD of master from 20-06-18
  popd
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
  OPTS+=('USER_VARS')
  echo "env USER_VARS set"
  echo "Extra users variables can be expanded by including the option \$USER_VARS on a playbook run."

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

export ANSIBLE_ACTION_PLUGINS="${ANSIBLE_EMBED_HOME}/repositories/ansible-config_template/action"
OPTS+=('ANSIBLE_ACTION_PLUGINS')
echo "env ANSIBLE_ACTION_PLUGINS set"

export ANSIBLE_CONNECTION_PLUGINS="${ANSIBLE_EMBED_HOME}/repositories/openstack-ansible-plugins/connection/"
OPTS+=('ANSIBLE_CONNECTION_PLUGINS')
echo "env ANSIBLE_CONNECTION_PLUGINS set"

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
