#!/bin/bash

#eg. KERNEL_VERSION="3.13.0-98"
KERNEL_VERSION=${KERNEL_VERSION:-false}

if [[ "${KERNEL_VERSION}" = false ]]; then
  echo "Please setup the KERNEL_VERSION before running this script"
  exit 1
fi

pushd ..
source functions.rc
for node in $(get_all_hosts); do
  ssh -q -t -o StrictHostKeyChecking=no 10.0.0.${node#*":"} KERNEL_VERSION="${KERNEL_VERSION}" 'bash -s' < tools/ubuntu-downgrade.sh
done
