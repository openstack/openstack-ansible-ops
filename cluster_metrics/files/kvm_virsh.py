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


import libvirt
import socket
from jsontoinflux import jsontoinflux

tag_keys = dict()
return_data = dict()
conn = libvirt.openReadOnly()
try:
    domains = conn.listDomainsID()
    return_data['kvm_vms'] = len(domains)
    return_data['kvm_total_vcpus'] = conn.getCPUMap()[0]
    return_data['kvm_scheduled_vcpus'] = 0
    for domain in domains:
        return_data['kvm_scheduled_vcpus'] += conn.lookupByID(
            domain
        ).maxVcpus()
    return_data['kvm_host_id'] = abs(hash(socket.getfqdn()))
except Exception:
    raise SystemExit('Plugin failure')
else:
    print(jsontoinflux('kvm', tag_keys, return_data))
finally:
    conn.close()
