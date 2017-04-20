#!/usr/bin/env bash
set -eu
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

# Load all functions
source functions.rc

# bring in variable definitions if there is a variables.sh file
[[ -f variables.sh ]] && source variables.sh

# Instruct the system do all of the require host setup
SETUP_HOST=${SETUP_HOST:-true}
[[ "${SETUP_HOST}" = true ]] && source setup-host.sh

# Instruct the system do all of the cobbler setup
SETUP_COBBLER=${SETUP_COBBLER:-true}
[[ "${SETUP_COBBLER}" = true ]] && source setup-cobbler.sh

# Instruct the system do all of the virsh setup
SETUP_VIRSH_NET=${SETUP_VIRSH_NET:-true}
[[ "${SETUP_VIRSH_NET}" = true ]] && source setup-virsh-net.sh

# Instruct the system to Kick all of the VMs
DEPLOY_VMS=${DEPLOY_VMS:-true}
[[ "${DEPLOY_VMS}" = true ]] && source deploy-vms.sh

# Instruct the system to deploy OpenStack Ansible
DEPLOY_OSA=${DEPLOY_OSA:-true}
[[ "${DEPLOY_OSA}" = true ]] && source config-deploy-node.sh
