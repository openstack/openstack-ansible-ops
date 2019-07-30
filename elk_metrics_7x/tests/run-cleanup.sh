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

set -e

export TEST_DIR="$(readlink -f $(dirname ${0})/../../)"

# Stop beat processes
pushd "${TEST_DIR}/elk_metrics_6x"
  for i in $(ls -1 install*beat.yml); do
    LOWER_BEAT="$(echo "${i}" | tr '[:upper:]' '[:lower:]')"
    BEAT_PARTIAL="$(echo ${LOWER_BEAT} | awk -F'.' '{print $1}')"
    BEAT="$(echo ${BEAT_PARTIAL} | awk -F'install' '{print $2}')"
    echo "Stopping ${BEAT}"
    (systemctl stop "${BEAT}" || true) &
    apt remove --purge -y "${BEAT}" || true
    if [[ -d "/etc/${BEAT}" ]]; then
      rm -rf "/etc/${BEAT}"
    fi
    if [[ -d "/var/lib/${BEAT}" ]]; then
      rm -rf "/var/lib/${BEAT}"
    fi
    if [[ -d "/etc/systemd/system/${BEAT}.service.d" ]]; then
      rm -rf "/etc/systemd/system/${BEAT}.service.d"
    fi
  done
popd

for i in $(grep -lri elastic /etc/apt/sources.list.d/); do
  rm "${i}"
done

# Stop and remove containers
for i in {1..3}; do
  if machinectl list-images | grep -v ubuntu | awk '/sub/ {print $1}' | xargs -n 1 machinectl kill; then
    sleep 1
  fi
done

for i in {1..3}; do
  if machinectl list-images | grep -v ubuntu | awk '/sub/ {print $1}' | xargs -n 1 machinectl remove; then
    sleep 1
  fi
done
