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
neutron net-create GATEWAY_NET \
    --shared \
    --router:external=True \
    --provider:physical_network=flat \
    --provider:network_type=flat

neutron subnet-create GATEWAY_NET 172.16.24.0/22 \
    --name GATEWAY_NET_SUBNET \
    --gateway 172.16.24.2 \
    --allocation-pool start=172.16.25.201,end=172.16.25.255 \
    --dns-nameservers list=true 172.16.24.2



# Create a basic VXLAN network
neutron net-create PRIVATE_NET \
    --shared \
    --router:external=True \
    --provider:network_type=vxlan \
    --provider:segmentation_id 101

neutron subnet-create PRIVATE_NET 192.168.0.0/24 \
    --name PRIVATE_NET_SUBNET



# Create a neutron router and wire it up to the GATEWAY_NET and PRIVATE_NET_SUBNET
ROUTER_ID="$(neutron router-create GATEWAY_NET_ROUTER | grep -w id | awk '{print $4}')"
neutron router-gateway-set \
    "${ROUTER_ID}" \
    "$(neutron net-list | awk '/GATEWAY_NET/ {print $2}')"

neutron router-interface-add \
    "${ROUTER_ID}" \
    "$(neutron subnet-list | awk '/PRIVATE_NET_SUBNET/ {print $2}')"



# Neutron security group setup
for id in "$(neutron security-group-list -f yaml | awk '/- id\:/ {print $3}')"; do
    # Allow ICMP
    neutron security-group-rule-create --protocol icmp \
                                       --direction ingress \
                                       "$id" || true
    # Allow all TCP
    neutron security-group-rule-create --protocol tcp \
                                       --port-range-min 1 \
                                       --port-range-max 65535 \
                                       --direction ingress \
                                       "$id" || true
    # Allow all UDP
    neutron security-group-rule-create --protocol udp \
                                       --port-range-min 1 \
                                       --port-range-max 65535 -\
                                       -direction ingress \
                                       "$id" || true
done
