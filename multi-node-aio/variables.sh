# Variables used by multi-node-aio
# Network subnet used for all the virtual machines
NETWORK_BASE=172.29
# DNS used throughout the deploy
#DNS_NAMESERVER=$(cat /etc/resolv.conf | grep -m 1 "nameserver" | sed "s/nameserver //")
DNS_NAMESERVER=8.8.8.8
