#!/usr/bin/env bash
# Copyright 2016, Rackspace US, Inc.
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

for i in $(find /opt/kapacitor/kapacitor_files/tickscripts -type f -name "*.tick"); do
    echo $i
    IFS='.' read -ra NAMES <<< "$i"
    IFS='/' read -ra NAMES <<< "${NAMES[-2]}"
    if [[ $i == *"batch"* ]]; then
      kapacitor define ${NAMES[-1]} -type batch -tick $i -dbrp telegraf.autogen
    else
      kapacitor define ${NAMES[-1]} -type stream -tick $i -dbrp telegraf.autogen
    fi
    kapacitor enable ${NAMES[-1]}
done
