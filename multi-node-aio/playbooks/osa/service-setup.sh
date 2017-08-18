#!/usr/bin/env bash

# Load service variables
source /root/openrc

# Provide defaults for unset variables
# Set first two octets of network used for containers, storage, etc
NETWORK_BASE=${NETWORK_BASE:-172.29}

# Create base flavors for the new deployment
for flavor in micro tiny mini small medium large xlarge heavy; do
  NAME="m1.${flavor}"
  ID="${ID:-0}"
  RAM="${RAM:-256}"
  DISK="${DISK:-1}"
  VCPU="${VCPU:-1}"
  SWAP="${SWAP:-0}"
  EPHEMERAL="${EPHEMERAL:-0}"
  nova flavor-delete $ID > /dev/null || echo "No Flavor with ID: [ $ID ] found to clean up"
  nova flavor-create $NAME $ID $RAM $DISK $VCPU --swap $SWAP --is-public true --ephemeral $EPHEMERAL --rxtx-factor 1
  let ID=ID+1
  let RAM=RAM*2
  if [ "$ID" -gt 5 ];then
    let VCPU=VCPU*2
    let DISK=DISK*2
    let EPHEMERAL=256
    let SWAP=4
  elif [ "$ID" -gt 4 ];then
    let VCPU=VCPU*2
    let DISK=DISK*4+$DISK
    let EPHEMERAL=$DISK/2
    let SWAP=4
  elif [ "$ID" -gt 3 ];then
    let VCPU=VCPU*2
    let DISK=DISK*4+$DISK
    let EPHEMERAL=$DISK/3
    let SWAP=4
  elif [ "$ID" -gt 2 ];then
    let VCPU=VCPU+$VCPU/2
    let DISK=DISK*4
    let EPHEMERAL=$DISK/3
    let SWAP=4
  elif [ "$ID" -gt 1 ];then
    let VCPU=VCPU+1
    let DISK=DISK*2+$DISK
  fi
done

# Neutron provider network setup
neutron net-create GATEWAY_NET \
    --router:external=True \
    --provider:physical_network=flat \
    --provider:network_type=flat

neutron subnet-create GATEWAY_NET ${NETWORK_BASE}.248.0/22 \
    --name GATEWAY_NET_SUBNET \
    --gateway ${NETWORK_BASE}.248.1 \
    --allocation-pool start=${NETWORK_BASE}.248.201,end=${NETWORK_BASE}.248.255 \
    --dns-nameservers list=true ${DNS_NAMESERVER}

# Neutron private network setup
neutron net-create PRIVATE_NET \
    --shared \
    --router:external=True \
    --provider:network_type=vxlan \
    --provider:segmentation_id 101

neutron subnet-create PRIVATE_NET 192.168.0.0/24 \
    --name PRIVATE_NET_SUBNET

# Neutron router setup
ROUTER_ID=$(neutron router-create GATEWAY_NET_ROUTER | grep -w id | awk '{print $4}')
neutron router-gateway-set \
    ${ROUTER_ID} \
    $(neutron net-list | awk '/GATEWAY_NET/ {print $2}')

neutron router-interface-add \
    ${ROUTER_ID} \
    $(neutron subnet-list | awk '/PRIVATE_NET_SUBNET/ {print $2}')

# Neutron security group setup
for id in $(neutron security-group-list -f yaml | awk '/- id\:/ {print $3}'); do
    # Allow ICMP
    neutron security-group-rule-create --protocol icmp \
                                       --direction ingress \
                                       $id || true
    # Allow all TCP
    neutron security-group-rule-create --protocol tcp \
                                       --port-range-min 1 \
                                       --port-range-max 65535 \
                                       --direction ingress \
                                       $id || true
    # Allow all UDP
    neutron security-group-rule-create --protocol udp \
                                       --port-range-min 1 \
                                       --port-range-max 65535 -\
                                       -direction ingress \
                                       $id || true
done

# Create some default images
wget http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img
glance image-create --name 'Ubuntu 14.04 LTS' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-14.04-server-cloudimg-amd64-disk1.img
rm ubuntu-14.04-server-cloudimg-amd64-disk1.img

wget http://uec-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img
glance image-create --name 'Ubuntu 16.04' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file ubuntu-16.04-server-cloudimg-amd64-disk1.img
rm ubuntu-16.04-server-cloudimg-amd64-disk1.img

wget http://dfw.mirror.rackspace.com/fedora/releases/24/CloudImages/x86_64/images/Fedora-Cloud-Base-24-1.2.x86_64.qcow2
glance image-create --name 'Fedora 24' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file Fedora-Cloud-Base-24-1.2.x86_64.qcow2
rm Fedora-Cloud-Base-24-1.2.x86_64.qcow2

wget http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
glance image-create --name 'CentOS 7' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file CentOS-7-x86_64-GenericCloud.qcow2
rm CentOS-7-x86_64-GenericCloud.qcow2

wget http://download.opensuse.org/repositories/Cloud:/Images:/Leap_42.1/images/openSUSE-Leap-42.1-OpenStack.x86_64-0.0.4-Build2.12.qcow2
glance image-create --name 'OpenSuse Leap 42' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file openSUSE-Leap-42.1-OpenStack.x86_64-0.0.4-Build2.12.qcow2
rm openSUSE-Leap-42.1-OpenStack.x86_64-0.0.4-Build2.12.qcow2

wget http://cdimage.debian.org/cdimage/openstack/current/debian-8.6.0-openstack-amd64.qcow2
glance image-create --name 'Debian 8.6.0' \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file debian-8.6.0-openstack-amd64.qcow2
rm debian-8.6.0-openstack-amd64.qcow2

wget http://cdimage.debian.org/cdimage/openstack/testing/debian-testing-openstack-amd64.qcow2
glance image-create --name "Debian TESTING $(date +%m-%d-%y)" \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file debian-testing-openstack-amd64.qcow2
rm debian-testing-openstack-amd64.qcow2

wget http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img
glance image-create --name "Cirros-0.3.4" \
                    --container-format bare \
                    --disk-format qcow2 \
                    --visibility public \
                    --progress \
                    --file cirros-0.3.4-x86_64-disk.img
rm cirros-0.3.4-x86_64-disk.img
