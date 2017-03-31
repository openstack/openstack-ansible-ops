#!/usr/bin/env bash
set -eu
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

# Reset the ssh-agent service to remove potential key issues
ssh_agent_reset

# Wait here for all nodes to be booted and ready with SSH
wait_ssh

# Export all system keys
mkdir -p /tmp/keys
for i in $(apt-key list | awk '/pub/ {print $2}' | awk -F'/' '{print $2}'); do
  apt-key export "$i" > "/tmp/keys/$i"
done

# Ensure that all running VMs have an updated apt-cache with keys
# and copy our http proxy settings into each VM (in the environment and apt.conf)
for node in $(get_all_hosts); do
  if [ ! -z ${http_proxy+x} ]; then
    ssh -q -n -f -o StrictHostKeyChecking=no 10.0.0.${node#*":"} "mkdir -p /tmp/keys; \
      echo \"http_proxy=$http_proxy\" >> /etc/environment; \
      echo \"https_proxy=$https_proxy\" >> /etc/environment; \
      echo \"no_proxy=localhost,127.0.0.1,10.0.0.200\" >> /etc/environment; \
      echo \"Acquire::http::Proxy \\\"$http_proxy\\\";\" >> /etc/apt/apt.conf"
  else
    ssh -q -n -f -o StrictHostKeyChecking=no 10.0.0.${node#*":"} "mkdir -p /tmp/keys"
  fi
  for i in /etc/apt/apt.conf.d/00-nokey /etc/apt/sources.list /etc/apt/sources.list.d/* /tmp/keys/*; do
    if [[ -f "$i" ]]; then
      scp "$i" "10.0.0.${node#*":"}:$i"
    fi
  done
  ssh -q -n -f -o StrictHostKeyChecking=no 10.0.0.${node#*":"} "(for i in /tmp/keys/*; do \
      apt-key add \$i; \
      apt-key adv --keyserver keyserver.ubuntu.com --recv-keys \$(basename \$i); done); \
    apt-get clean; \
    apt-get update"
done
