#!/usr/bin/env bash
# Copyright 2017, Rackspace US, Inc.
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

source openrc



# Generate a set of typical flavors
for flavor in micro tiny mini small medium large xlarge heavy; do
  NAME="m1.${flavor}"
  ID="${ID:-0}"
  RAM="${RAM:-256}"
  DISK="${DISK:-1}"
  VCPU="${VCPU:-1}"
  SWAP="${SWAP:-0}"
  EPHEMERAL="${EPHEMERAL:-0}"
  openstack flavor delete "$ID" > /dev/null || echo "No Flavor with ID: [ $ID ] found to clean up"
  openstack flavor create "$NAME" --id "$ID" --ram "$RAM" --disk "$DISK" --vcpu "$VCPU" --swap "$SWAP" --public --ephemeral "$EPHEMERAL" --rxtx-factor 1
  let ID=ID+1
  let RAM=RAM*2
  if [ "$ID" -gt 5 ];then
    let VCPU=VCPU*2
    let DISK=DISK*2
    let EPHEMERAL=256
    let SWAP=4
  elif [ "$ID" -gt 4 ];then
    let VCPU=VCPU*2
    let DISK=DISK*4+"$DISK"
    let EPHEMERAL="$DISK/2"
    let SWAP=4
  elif [ "$ID" -gt 3 ];then
    let VCPU=VCPU*2
    let DISK=DISK*4+"$DISK"
    let EPHEMERAL="$DISK/3"
    let SWAP=4
  elif [ "$ID" -gt 2 ];then
    let VCPU=VCPU+"$VCPU/2"
    let DISK=DISK*4
    let EPHEMERAL="$DISK/3"
    let SWAP=4
  elif [ "$ID" -gt 1 ];then
    let VCPU=VCPU+1
    let DISK=DISK*2+"$DISK"
  fi
done
