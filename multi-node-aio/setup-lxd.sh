# Load all functions
source functions.rc

# Ensure LXD is installed
apt install -y lxd lxd-client lxd-tools criu

# This is because of https://github.com/lxc/lxd/issues/2195
mkdir /mnt/proc
mount -t proc proc /mnt/proc

# Initialize LXD
lxd init -- auto \
--storage-backend zfs \
--storage-pool tank \
--storage-create-loop 100
--network-address 0.0.0.0
--network-port 8443
--trust-password password

# Move lxd-brdige config file to /etc/default/lxd-bridge
cp templates/lxd-bridge /etc/default/lxd-bridge

systemctl enable lxd-bridge
systemctl start lxd-bridge
