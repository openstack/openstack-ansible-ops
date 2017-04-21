#!/usr/bin/env bash

# Load all functions
source functions.rc

# bring in variable definitions if there is a variables.sh file
[[ -f variables.sh ]] && source variables.sh

# Copy private key and public key to deploy node
scp -r -o StrictHostKeyChecking=no  ~/.ssh deploy1:/root/

# Copy multi-node-aio folder to deploy node
scp -r -o StrictHostKeyChecking=no  ../multi-node-aio deploy1:/root

# Deploy openstack-ansible from deploy node and export all variables deploy-osa.sh needs
ssh -o StrictHostKeyChecking=no deploy1 "export NETWORK_BASE=${NETWORK_BASE} RUN_OSA=${RUN_OSA} " \
"OSA_BRANCH=${OSA_BRANCH} PRE_CONFIG_OSA=${PRE_CONFIG_OSA}; apt update; cd /root/multi-node-aio/; ./deploy-osa.sh"

# Add 2222 rules to iptables for ssh directly into deployment node.
iptables_filter_rule_add nat 'PREROUTING -p tcp --dport 2222 -j DNAT --to 10.0.0.150:22'

scp -o StrictHostKeyChecking=no deploy1:/opt/openstack-ansible/playbooks/vars/configs/haproxy_config.yml .
PORTS="$(get_osad_ports) $OSA_PORTS"
for port in $PORTS ; do
  iptables_filter_rule_add nat "PREROUTING -p tcp --dport ${port} -j DNAT --to 10.0.0.150:${port}"
done
