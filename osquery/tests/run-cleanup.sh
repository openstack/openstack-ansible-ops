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
(systemctl stop osqueryd.service || true) &

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
