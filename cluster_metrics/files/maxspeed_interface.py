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
# This script gathers the maximum network speed of each
# interface and outputs to Influx Protocol Line format


import subprocess
from jsontoinflux import jsontoinflux

output = subprocess.check_output("netstat -i\
", shell=True, stderr=subprocess.PIPE)
return_data = dict()
tag_keys = dict()
list = []
i = 0
for line in output.splitlines():
    if i > 1:
        interface = line.split(" ")[0].strip()
        try:
            speed = subprocess.check_output("\
            ethtool " + interface + " | grep -i Speed\
            ", shell=True, stderr=subprocess.PIPE).strip().split(":")
            return_data["max_speed"] = float(speed[1].strip()[:-4])
            tag_keys["interface"] = interface
            print(jsontoinflux('interface_speed', tag_keys, return_data))
            tag_keys = dict()
            return_data = dict()
        except:
            continue
    i = i + 1
