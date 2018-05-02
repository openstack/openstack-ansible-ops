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

if [[ ! -f "/opt/ansible25/bin/ansible" ]]; then
  apt-get update
  apt-get -y install python3-virtualenv || apt-get -y install python-virtualenv
  virtualenv --python=/usr/bin/python3 /opt/ansible25 || virtualenv --python=/usr/bin/python2 /opt/ansible25
  /opt/ansible25/bin/pip install --upgrade ansible==2.5.2.0 --isolated
fi

if [[ ! -d "/opt/ansible25/repositories/ansible-config_template" ]]; then
  mkdir -p /opt/ansible25/repositories
  git clone https://github.com/openstack/ansible-config_template /opt/ansible25/repositories/ansible-config_template
fi

if [[ ! -d "/opt/ansible25/repositories/roles/systemd_service" ]]; then
  mkdir -p /opt/ansible25/repositories
  git clone https://github.com/openstack/ansible-role-systemd_service /opt/ansible25/repositories/roles/systemd_service
fi

if [[ -f "/etc/openstack_deploy/openstack_inventory.json" ]]; then
  mkdir -p /opt/ansible25/inventory
  cat > /opt/ansible25/inventory/openstack_inventory.sh <<EOF
#!/usr/bin/env bash
cat /etc/openstack_deploy/openstack_inventory.json
EOF
  chmod +x /opt/ansible25/inventory/openstack_inventory.sh
fi

export ANSIBLE_ROLES_PATH="/opt/ansible25/repositories/roles"
export ANSIBLE_ACTION_PLUGINS="/opt/ansible25/repositories/ansible-config_template/action"
export ANSIBLE_INVENTORY="${ANSIBLE_INVENTORY:-/opt/ansible25/inventory/openstack_inventory.sh}"

export ANSIBLE_USER_VARS="$(for i in $(ls /etc/openstack_deploy/user_*secret*.yml); do echo -n "-e@$i "; done)"
