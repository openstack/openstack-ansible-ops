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

KERNEL_IMAGE=$(glance image-list | awk '/baremetal-ubuntu-xenial.vmlinuz/ {print $2}')
INITRAMFS_IMAGE=$(glance image-list | awk '/baremetal-ubuntu-xenial.initrd/ {print $2}')
DEPLOY_RAMDISK=$(glance image-list | awk '/ironic-deploy.initramfs/ {print $2}')
DEPLOY_KERNEL=$(glance image-list | awk '/ironic-deploy.kernel/ {print $2}')

if ironic node-list | grep "$inventory_hostname"; then
    NODE_UUID=$(ironic --ironic-api-version 1.22 node-list | awk "/$inventory_hostname/ {print \$2}")
else
    NODE_UUID=$(ironic --ironic-api-version 1.22 node-create \
      -d agent_ipmitool \
      -i ipmi_address="$ipmi_address" \
      -i ipmi_password="$ipmi_password" \
      -i ipmi_username="$ipmi_user" \
      -i deploy_ramdisk="${DEPLOY_RAMDISK}" \
      -i deploy_kernel="${DEPLOY_KERNEL}" \
      -p cpus=$image_vcpu \
      -p memory_mb=$image_ram \
      -p local_gb=$ironic_disk_available \
      -p size=$image_total_disk_size \
      -p cpu_arch=$image_cpu_arch \
      -p capabilities=boot_option:local,disk_label:gpt \
      -n $inventory_hostname \
      --resource-class ${RESOURCE_CLASS} | awk '/ uuid / {print $4}')
    ironic --ironic-api-version 1.22 port-create -n "$NODE_UUID" \
                       -a $Port1NIC_MACAddress
fi

# flavor creation
if ! nova flavor-list | grep "${RESOURCE_CLASS}"; then
    FLAVOR_ID=$(cat /proc/sys/kernel/random/uuid)
    nova flavor-create ${RESOURCE_CLASS} ${FLAVOR_ID} ${image_ram} ${image_disk_root} ${image_vcpu}
    nova flavor-key ${RESOURCE_CLASS} set cpu_arch=x86_64
    nova flavor-key ${RESOURCE_CLASS} set capabilities:boot_option="local"
    nova flavor-key ${RESOURCE_CLASS} set capabilities:disk_label="gpt"
    nova flavor-key ${RESOURCE_CLASS} set resources:VCPU=0
    nova flavor-key ${RESOURCE_CLASS} set resources:MEMORY_MB=0
    nova flavor-key ${RESOURCE_CLASS} set resources:DISK_GB=0
    nova flavor-key ${RESOURCE_CLASS} set resources:CUSTOM_${NOVA_RESOURCE_FLAVOR_NAME}=1
fi

ironic --ironic-api-version 1.22 node-set-provision-state "${NODE_UUID}" manage
sleep 1m  # necessary to get power state
ironic --ironic-api-version 1.22 node-set-provision-state "${NODE_UUID}" provide
