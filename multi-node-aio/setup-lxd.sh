# ZFS pool name
export ZFS_NAME=${ZFS_NAME:-lxd_pool}
set -x

# Load all functions
source functions.rc

# Ensure LXD is installed
apt install -y lxd lxd-client lxd-tools criu

# This is because of https://github.com/lxc/lxd/issues/2195
mkdir -p /mnt/proc
mount -t proc proc /mnt/proc || true

if zfs list | grep ${ZFS_NAME}; then
    zpool destroy ${ZFS_NAME}
fi

# if there are any existing images, don't initialize
image=`lxc image list | grep -vE '\+|DESCRIPTION' | awk '{print $3}'`
if [ $image ]; then
    for i in `lxc image list | grep -Ev '\+|FINGERPRINT' | awk '{print $3}'`; do
        lxc image delete $i
    done
fi

# Initialize LXD
lxd init --auto \
--storage-backend zfs \
--storage-pool ${ZFS_NAME} \
--storage-create-loop 100 \
--network-address 0.0.0.0 \
--network-port 8443 \
--trust-password password

# Move lxd-brdige config file to /etc/default/lxd-bridge
cp templates/lxd_style/lxc-bridge /etc/default/lxd-bridge

systemctl enable lxd-bridge
systemctl start lxd-bridge

# Create and setup profiles
# Don't' fail if it already exists
lxc profile create infra || true
lxc profile create compute || true
cat templates/lxd_style/lxc_profiles/infra.yml | lxc profile edit infra
cat templates/lxd_style/lxc_profiles/compute.yml | lxc profile edit compute
