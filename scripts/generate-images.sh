#!/usr/bin/env bash
# Copyright 2017, Rackspace US, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

source openrc



# Image upload function.
#  Download an image, upload into glance, remove downloaded file.
function image_upload {
  IMAGE_URL="${1}"
  IMAGE_FILE="$(basename ${IMAGE_URL})"
  IMAGE_NAME="${2}"
  if [[ ! -f "${IMAGE_FILE}" ]]; then
    wget "${IMAGE_URL}" -O "${IMAGE_FILE}" || (rm "${IMAGE_FILE}" && exit 1)
  else
    echo "file found ${IMAGE_FILE}"
  fi
  if [[ "$?" == 0 ]]; then
    glance image-create --name "${IMAGE_NAME}" \
                        --container-format bare \
                        --disk-format qcow2 \
                        --visibility public \
                        --progress \
                        --file "${IMAGE_FILE}" && rm "${IMAGE_FILE}"
  fi
}



# Create some default images
#  USAGE: image_upload $URL $NAME
image_upload http://uec-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img ubuntu-14.04-amd64
image_upload http://uec-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img ubuntu-16.04-amd64
image_upload http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2 centos-7-amd64
image_upload http://cdimage.debian.org/cdimage/openstack/current/debian-9.2.0-openstack-amd64.qcow2 debian-9.2.0-amd64
image_upload http://download.cirros-cloud.net/0.3.4/cirros-0.3.4-x86_64-disk.img cirros-0.3.4-amd64
image_upload http://dfw.mirror.rackspace.com/fedora/releases/26/CloudImages/x86_64/images/Fedora-Cloud-Base-26-1.5.x86_64.qcow2 fedora-26-amd64
image_upload http://download.opensuse.org/repositories/Cloud:/Images:/Leap_42.3/images/openSUSE-Leap-42.3-OpenStack.x86_64.qcow2 opensuse-leap-42.3-amd64
