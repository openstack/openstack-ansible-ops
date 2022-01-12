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



# Create a basic flat network
openstack network create GATEWAY_NET \
    --share \
    --external \
    --provider-physical-network flat \
    --provider-network-type flat

openstack subnet create GATEWAY_SUBNET \
    --subnet-range 172.16.24.0/22 \
    --network GATEWAY_NET \
    --gateway 172.16.24.2 \
    --allocation-pool start=172.16.25.201,end=172.16.25.255 \
    --dns-nameserver 172.16.24.2



# Create a basic VXLAN network
openstack network create PRIVATE_NET \
    --share \
    --provider-network-type vxlan \
    --provider-segment 101

openstack subnet create PRIVATE_SUBNET \
    --subnet-range 192.168.0.0/24 \
    --network PRIVATE_NET



# Create a neutron router and wire it up to the GATEWAY_NET and PRIVATE_NET_SUBNET
ROUTER_ID="$(openstack router create GATEWAY_NET_ROUTER -c id | grep -w id | awk '{print $4}')"
openstack router set "${ROUTER_ID}" \
    --external-gateway "$(openstack network list | awk '/GATEWAY_NET/ {print $2}')"

openstack router add subnet \
    "${ROUTER_ID}" \
    "$(openstack subnet list | awk '/PRIVATE_SUBNET/ {print $2}')"



# Neutron security group setup
SECGRP_ID="$(openstack security group create MNAIO_SECGRP -c id | grep -w id | awk '{print $4}')"
# Allow ICMP
openstack security group rule create --protocol icmp \
                                     --ingress \
                                     "$SECGRP_ID"

# Allow all TCP
openstack security group rule create --protocol tcp \
                                     --ingress \
                                     "$SECGRP_ID"

# Allow all UDP
openstack security group rule create --protocol udp \
                                     --ingress \
                                     "$SECGRP_ID"
