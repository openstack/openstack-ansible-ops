#!/usr/bin/env bash

set -e -u

inventory_hostname=123456-node01
Port1NIC_MACAddress="ab:cd:ef:gh:ij:kl"

# IPMI details
ipmi_address="0.0.0.0"
ipmi_password="password"
ipmi_user="username"

# Image details belonging to a particular node
image_vcpu=12
image_ram=254802
ironic_disk_available=80  # for the scheduler, this should be BIGGER than image_disk_root
image_disk_root=40
image_total_disk_size=3600
image_cpu_arch="x86_64"
RESOURCE_CLASS="baremetal.general"
NOVA_RESOURCE_FLAVOR_NAME=${RESOURCE_CLASS//./_}
NOVA_RESOURCE_FLAVOR_NAME=$(echo ${NOVA_RESOURCE_FLAVOR_NAME//-/_} | awk '{print toupper($0)}')

KERNEL_IMAGE=$(openstack image-list | awk '/baremetal-ubuntu-xenial.vmlinuz/ {print $2}')
INITRAMFS_IMAGE=$(openstack image-list | awk '/baremetal-ubuntu-xenial.initrd/ {print $2}')
DEPLOY_RAMDISK=$(openstack image-list | awk '/ironic-deploy.initramfs/ {print $2}')
DEPLOY_KERNEL=$(openstack image-list | awk '/ironic-deploy.kernel/ {print $2}')

if openstack baremetal node-list | grep "$inventory_hostname"; then
    NODE_UUID=$(openstack baremetal --os-baremetal-api-version 1.22 node-list | awk "/$inventory_hostname/ {print \$2}")
else
    NODE_UUID=$(openstack baremetal --os-baremetal-api-version 1.22 node create \
      --driver agent_ipmitool \
      --driver-info ipmi_address="$ipmi_address" \
      --driver-info ipmi_password="$ipmi_password" \
      --driver-info ipmi_username="$ipmi_user" \
      --driver-info deploy_ramdisk="${DEPLOY_RAMDISK}" \
      --driver-info deploy_kernel="${DEPLOY_KERNEL}" \
      --property cpus=$image_vcpu \
      --property memory_mb=$image_ram \
      --property local_gb=$ironic_disk_available \
      --property size=$image_total_disk_size \
      --property cpu_arch=$image_cpu_arch \
      --property capabilities=boot_option:local,disk_label:gpt \
      -n $inventory_hostname \
      --resource-class ${RESOURCE_CLASS} | awk '/ uuid / {print $4}')
    openstack baremetal --os-baremetal-api-version 1.22 port create --node "$NODE_UUID" \
                        $Port1NIC_MACAddress
fi

# flavor creation
if ! openstack flavor list | grep "${RESOURCE_CLASS}"; then
    openstack flavor create \
          --ram ${image_ram} \
          --disk ${image_disk_root} \
          --vcpus ${image_vcpu} \
           ${RESOURCE_CLASS}
    openstack flavor set \
       --property cpu_arch=x86_64 \
       --property capabilities:boot_option="local" \
       --property capabilities:disk_label="gpt" \
       --property resources:VCPU=0 \
       --property resources:MEMORY_MB=0 \
       --property resources:DISK_GB=0 \
       --property resources:CUSTOM_${NOVA_RESOURCE_FLAVOR_NAME}=1 \
        ${RESOURCE_CLASS}
fi

openstack baremetal --os-baremetal-api-version 1.22 node manage "${NODE_UUID}"
sleep 1m  # necessary to get power state
openstack baremetal --os-baremetal-api-version 1.22 node provide "${NODE_UUID}"
