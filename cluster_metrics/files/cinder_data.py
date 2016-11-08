#!/usr/bin/env python
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
#
# This script calls the cinder API and gathers the volume group capacity
# information and outputs to Influx Protocol Line format
import subprocess
from jsontoinflux import jsontoinflux

output = subprocess.check_output("/bin/bash -l -c\
   'source /home/openrc;cinder get-pools --detail|\
      grep -w \"total_capacity_gb\|free_capacity_gb\|name\"'\
         ", shell=True, stderr=subprocess.PIPE)
list = []
tag_keys = dict()
return_data = dict()
for line in output.splitlines():
    cols = line.split("|")
    if cols[1].strip() in list:
        return_data['cinder_used_percentage'] =\
            100 * (1 - return_data['cinder_free_capacity_gb'] /
                   return_data['cinder_total_capacity_gb'])
        print(jsontoinflux('cinder', tag_keys, return_data))
        list = []
        return_data = dict()
        tag_keys = dict()
    try:
        return_data["cinder_" + cols[1].strip()] = float(cols[2].strip())
    except:
        tag_keys["cinder_" + cols[1].strip()] = cols[2].strip()
    list.append(cols[1].strip())
return_data['cinder_used_percentage'] =\
    100 * (1 - return_data['cinder_free_capacity_gb'] /
           return_data['cinder_total_capacity_gb'])
print(jsontoinflux('cinder', tag_keys, return_data))
