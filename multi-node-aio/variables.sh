# Variables used by multi-node-aio
# Network subnet used for all the virtual machines
NETWORK_BASE=172.29
# DNS used throughout the deploy
#DNS_NAMESERVER=$(cat /etc/resolv.conf | grep -m 1 "nameserver" | sed "s/nameserver //")
DNS_NAMESERVER=8.8.8.8

# By default AIO deploy overrides apt-sources, if things like a local mirror are already
# set up then this script will override these. This option allows for the override to be
# disabled.
OVERRIDE_SOURCES=true
