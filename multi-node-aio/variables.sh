# Variables used by multi-node-aio
# Network subnet used for all the virtual machines
NETWORK_BASE="${NETWORK_BASE:-172.29}"
# DNS used throughout the deploy
#DNS_NAMESERVER=$(cat /etc/resolv.conf | grep -m 1 "nameserver" | sed "s/nameserver //")
DNS_NAMESERVER="${DNS_NAMESERVER:-8.8.8.8}"

# By default AIO deploy overrides apt-sources, if things like a local mirror are already
# set up then this script will override these. This option allows for the override to be
# disabled.
OVERRIDE_SOURCES="${OVERRIDE_SOURCES:-true}"

# What branch of Openstack-Ansible are we deploying from
OSA_BRANCH="${OSA_BRANCH:-master}"

# What is the default disk device name
DEVICE_NAME="${DEVICE_NAME:-vda}"

# What default network device should we use for Cobbler
DEFAULT_NETWORK="${DEFAULT_NETWORK:-eth0}"

# What is the default virtual machine disk size in GB
VM_DISK_SIZE="${VM_DISK_SIZE:-252}"

# Do we want to do all the required host setup
SETUP_HOST="${SETUP_HOST:-true}"

# Do we want to do disk partitioning or is there a partition ready to use
PARTITION_HOST="${PARTITION_HOST:-true}"

# Do we want to set up networking on the host for Virsh
SETUP_VIRSH_NET="${SETUP_VIRSH_NET:-true}"

# When the virtual machines are re-kicked do we format them
VM_IMAGE_CREATE="${VM_IMAGE_CREATE:-true}"

# Should we run the deploy Openstack-Ansible script at the end of the build script
DEPLOY_OSA="${DEPLOY_OSA:-true}"

# Should we pre-configure the environment before we deploy OpenStack-Ansible
PRE_CONFIG_OSA="${PRE_CONFIG_OSA:-true}"

# Should we run the final deploy of OpenStack-Ansible
RUN_OSA="${RUN_OSA:-true}"

# Default service ports
OSA_PORTS="${OSA_PORTS:-6080 6082 443 80}"