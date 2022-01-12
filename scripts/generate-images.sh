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
    openstack image create "${IMAGE_NAME}" \
                           --container-format bare \
                           --disk-format qcow2 \
                           --public \
                           --progress \
                           --file "${IMAGE_FILE}" && rm "${IMAGE_FILE}"
  fi
}



# Create some default images
#  USAGE: image_upload $URL $NAME
image_upload https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img ubuntu-18.04-amd64
image_upload https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img ubuntu-20.04-amd64
image_upload https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img ubuntu-22.04-amd64
image_upload https://cloud.centos.org/centos/9-stream/x86_64/images/CentOS-Stream-GenericCloud-9-20220216.0.x86_64.qcow2 centos-9-stream-20220216-x86_64
image_upload https://cloud.debian.org/images/cloud/OpenStack/current-10/debian-10-openstack-amd64.qcow2 debian-10-openstack-amd64
image_upload https://download.cirros-cloud.net/0.5.2/cirros-0.5.2-x86_64-disk.img cirros-0.5.2-x86_64
