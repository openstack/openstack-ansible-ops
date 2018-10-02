#!/usr/bin/env bash

# This script is set up to be run on infra01 and on ubunut xenial (16.04), but could be run on any node as long as the infra01_util node is in the hosts file.
# You can also define/export the UTILITY01_HOSTNAME yourself.

set -e -u

function cleanup {
  # it's ok if we have some errors on cleanup
  set +e
  unset DIB_DEV_USER_USERNAME DIB_DEV_USER_PASSWORD DIB_DEV_USER_PWDLESS_SUDO
  unset ELEMENTS_PATH DIB_CLOUD_INIT_DATASOURCES DIB_RELEASE DISTRO_NAME
  unset DIB_HPSSACLI_URL IRONIC_AGENT_VERSION
  unset -f make-base-image
  unset -f cleanup
  deactivate
}
# clean up our variables on exit, even exit on error
trap cleanup EXIT

function make-base-image {
  disk-image-create -o baremetal-$DISTRO_NAME-$DIB_RELEASE $DISTRO_NAME baremetal bootloader dhcp-all-interfaces local-config proliant-tools slow-network ${DEBUG_USER_ELEMENT:-""}

  rm -R *.d/
  scp -o StrictHostKeyChecking=no baremetal-$DISTRO_NAME-$DIB_RELEASE* "${UTILITY01_HOSTNAME}":~/images
  rm baremetal-$DISTRO_NAME-$DIB_RELEASE*  # no reason to keep these around

  VMLINUZ_UUID=$(ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "source ~/openrc; openstack image create \
                                    --public \
                                    --disk-format aki \
                                    --property hypervisor_type=baremetal \
                                    --protected \
                                    --container-format aki \
                                    baremetal-$DISTRO_NAME-$DIB_RELEASE.vmlinuz < ~/images/baremetal-$DISTRO_NAME-$DIB_RELEASE.vmlinuz" | awk '/\| id/ {print $4}')
  INITRD_UUID=$(ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "source ~/openrc; openstack image create \
                                   --public \
                                   --disk-format ari \
                                   --property hypervisor_type=baremetal \
                                   --protected \
                                   --container-format ari \
                                   baremetal-$DISTRO_NAME-$DIB_RELEASE.initrd < ~/images/baremetal-$DISTRO_NAME-$DIB_RELEASE.initrd" | awk '/\| id/ {print $4}')
  ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "source ~/openrc; openstack image create \
    --public \
    --disk-format qcow2 \
    --container-format bare \
    --property hypervisor_type=baremetal \
    --property kernel_id=${VMLINUZ_UUID} \
    --protected \
    --property ramdisk_id=${INITRD_UUID} \
      baremetal-$DISTRO_NAME-$DIB_RELEASE < ~/images/baremetal-$DISTRO_NAME-$DIB_RELEASE.qcow2"

}

# install needed binaries
apt-get install -y kpartx parted qemu-utils virtualenv

mkdir -p ~/dib
pushd ~/dib
  virtualenv env
  set +u
  source env/bin/activate
  set -u

  # newton pip.conf sucks
  if [[ -f ~/.pip/pip.conf ]]; then
    mv ~/.pip/pip.conf{,.bak}
  fi
  # install dib
  pip install pbr  # newton pbr is too old
  if [[ ! -d ~/dib/diskimage-builder ]]; then
    git clone https://github.com/openstack/diskimage-builder/ -b 2.10.1
  fi
  # let's use a newer kernel for interfaces we may need
  if ! grep -q linux-image-generic-lts-xenial ~/dib/diskimage-builder/diskimage_builder/elements/ubuntu/package-installs.yaml; then
    echo 'linux-image-generic-lts-xenial:' > ~/dib/diskimage-builder/diskimage_builder/elements/ubuntu/package-installs.yaml
  fi
  pushd diskimage-builder
    pip install .
  popd
  if [[ -f ~/.pip/pip.conf.bak ]]; then
    mv ~/.pip/pip.conf.bak ~/.pip/pip.conf
  fi
  if [[ ! -e ~/dib/openstack-ansible-ops ]]; then
    git clone https://github.com/openstack/openstack-ansible-ops ~/dib/openstack-ansible-ops
  fi

  UTILITY01_HOSTNAME="${UTILITY01_HOSTNAME:-$(grep infra01_util /etc/hosts | awk '{print $NF}')}"

  # create image directory in util01 container
  ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "mkdir -p ~/images"

  # set up envars for the deploy image debug user
  export DIB_DEV_USER_USERNAME=debug-user
  export DIB_DEV_USER_PASSWORD=secrete
  export DIB_DEV_USER_PWDLESS_SUDO=yes
  # Uncomment the following line to enable a debug user login
  #export DEBUG_USER_ELEMENT=devuser

  # set up envars for all images
  export DIB_CLOUD_INIT_DATASOURCES="Ec2, ConfigDrive, OpenStack"
  export ELEMENTS_PATH=~/dib/openstack-ansible-ops/elements
  # default to ubuntu xenial
  export DIB_RELEASE=xenial
  export DISTRO_NAME=ubuntu

  # set up envars for the deploy image ironic agent
  # export DIB_HPSSACLI_URL="http://downloads.hpe.com/pub/softlib2/software1/pubsw-linux/p1857046646/v109216/hpssacli-2.30-6.0.x86_64.rpm"
  export IRONIC_AGENT_VERSION="stable/rocky"
  # create the deploy image
  disk-image-create --install-type source -o ironic-deploy ironic-agent ubuntu proliant-tools ${DEBUG_USER_ELEMENT:-""}

  rm ironic-deploy.vmlinuz  # not needed or uploaded
  rm -R *.d/  # don't need dib dirs
  scp -o StrictHostKeyChecking=no ironic-deploy* "${UTILITY01_HOSTNAME}":~/images
  rm ironic-deploy*  # no reason to keep these around

  ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "source ~/openrc; openstack image create \
    --public \
    --disk-format aki \
    --property hypervisor_type=baremetal \
    --protected \
    --container-format aki < ~/images/ironic-deploy.kernel \
    ironic-deploy.kernel"

  ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "source ~/openrc; openstack image create \
    --public \
    --disk-format ari \
    --property hypervisor_type=baremetal \
    --protected \
    --container-format ari < ~/images/ironic-deploy.initramfs \
     ironic-deploy.initramfs"

  # Ubuntu Xenial final image
  make-base-image

  # Ubuntu Trusty final image
  export DIB_RELEASE=trusty
  export DISTRO_NAME=ubuntu
  make-base-image

  # CentOS 7 final image
  export DIB_RELEASE=7
  export DISTRO_NAME=centos7
  make-base-image
popd

# utility container doesn't have much space...
ssh -o StrictHostKeyChecking=no "${UTILITY01_HOSTNAME}" "rm ~/images -R"
