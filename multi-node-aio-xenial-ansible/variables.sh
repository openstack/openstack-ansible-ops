# Variables used by multi-node-aio
# Network subnet used for all the virtual machines
NETWORK_BASE="${NETWORK_BASE:-10.29}"
# DNS used throughout the deploy
DNS_NAMESERVER=$(cat /etc/resolv.conf | grep -m 1 "nameserver" | sed "s/nameserver //")
#DNS_NAMESERVER="${DNS_NAMESERVER:-8.8.8.8}"

# By default AIO deploy overrides apt-sources, if things like a local mirror are already
# set up then this script will override these. This option allows for the override to be
# disabled.
OVERRIDE_SOURCES="${OVERRIDE_SOURCES:-false}"

# What branch of Openstack-Ansible are we deploying from
OSA_BRANCH="${OSA_BRANCH:-stable/newton}"

# What is the default disk device name
DEVICE_NAME="${DEVICE_NAME:-vda}"

# What default network device should we use
DEFAULT_NETWORK="${DEFAULT_NETWORK:-ens3}"

# What is the default virtual machine disk size in GB
VM_DISK_SIZE="${VM_DISK_SIZE:-252}"

# Do we want to do all the required host setup
SETUP_HOST="${SETUP_HOST:-true}"

# What fisk shall we use for the default data
DATA_DISK_DEVICE="${DATA_DISK_DEVICE:-sdb}"

# Do we want to do disk partitioning or is there a partition ready to use
PARTITION_HOST="${PARTITION_HOST:-true}"

# Force partition - If the above variable is set to -F then we will use the force
# option of MKFS so there is no confirm
FORCE_PARTITION="-F"

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

# Should we use PXEboot
SETUP_PXEBOOT="${SETUP_PXEBOOT:-true}"

# Should we create the virtual machines
CREATE_VMS="${CREATE_VMS:-true}"

# Should we configure the virtual machines
CONFIGURE_VMS="${CONFIGURE_VMS:-true}"

# Container vms - override the container virtual machines with xenial
CONTAINER_VMS="${CONTAINER_VMS:-xenial}"

# Ethernet type, this needs to be ens for Xenial and is for
# templates/network-interfaces/vm.openstackci.local-bonded-bridges.cfg file
ETH_TYPE="${ETH_TYPE:-ens}"
