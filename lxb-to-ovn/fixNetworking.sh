#!/bin/bash
# Copyright 2026, BBC Research & Development
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
# When Nova migrates a VM to an OVN host from an LXB host the bridge name will be incorrect.
# This script re-associated the VM's tap interface with the correct bridge for OVN
set -e
TAP_NAME=$1
CLEANUP_ONLY=$2
QOS=$(ovs-vsctl get port $TAP_NAME qos)
INTERFACE=$(ovs-vsctl get port $TAP_NAME interface)
EXTIDS=$(ovs-vsctl get interface ${INTERFACE:1:-1} external_ids)
ovs-vsctl del-port $TAP_NAME
if [[ $CLEANUP_ONLY -eq 1 ]]; then
  ovs-vsctl destroy interface $INTERFACE
  ovs-vsctl destroy qos $QOS
else
  ovs-vsctl add-port br-int $TAP_NAME
  ovs-vsctl set port $TAP_NAME qos=$QOS
  INTERFACE=$(ovs-vsctl get port $TAP_NAME interface)
  EXTIDS_FMT=\'${EXTIDS:1:-1}\'
  eval ovs-vsctl set interface ${INTERFACE:1:-1} external_ids=${EXTIDS_FMT}
  tc qdisc replace dev $TAP_NAME root noqueue
fi
