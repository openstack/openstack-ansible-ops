#!/usr/bin/env bash
# Copyright 2015, Rackspace US, Inc.
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

set -o pipefail
set -euov

BINDEP_FILE=${BINDEP_FILE:-bindep.txt}

source /etc/os-release || source /usr/lib/os-release

case "${ID,,}" in
    *suse*)
        # Need to pull libffi and python-pyOpenSSL early
        # because we install ndg-httpsclient from pip on Leap 42.1
        [[ "${VERSION}" == "42.1" ]] && extra_suse_deps="libffi-devel python-pyOpenSSL"
        sudo zypper -n in python-devel lsb-release ${extra_suse_deps:-}
        ;;
    amzn|centos|rhel)
        sudo yum install -y python-devel redhat-lsb-core
        ;;
    ubuntu|debian)
        sudo apt-get update && sudo apt-get install -y python-dev lsb-release
        ;;
    *)
        echo "Unsupported distribution: ${ID,,}"
        exit 1
esac

# Install pip
if ! which pip &>/dev/null; then
    curl --silent --show-error --retry 5 \
        https://bootstrap.pypa.io/pip/3.2/get-pip.py | sudo python2.7
fi

# Install bindep and tox
sudo pip install 'bindep>=2.4.0' tox

# CentOS 7 requires two additional packages:
#   redhat-lsb-core - for bindep profile support
#   epel-release    - required to install python-ndg_httpsclient/python2-pyasn1
if [[ ${ID,,} == "centos" ]]; then
    sudo yum -y install redhat-lsb-core epel-release yum-utils
    # epel-release could be installed but not enabled (which is very common
    # in openstack-ci) so enable it here if needed
    sudo yum-config-manager --enable epel || true
# openSUSE 42.1 does not have python-ndg-httpsclient
elif [[ ${ID,,} == *suse* ]] && [[ ${VERSION} == "42.1" ]]; then
    sudo pip install ndg-httpsclient
fi

# Get a list of packages to install with bindep. If packages need to be
# installed, bindep exits with an exit code of 1.
BINDEP_PKGS=$(bindep -b -f ${BINDEP_FILE} test || true)
echo "Packages to install: ${BINDEP_PKGS}"

# Install OS packages using bindep
if [[ ${#BINDEP_PKGS} > 0 ]]; then
    case "${ID,,}" in
        *suse*)
            sudo zypper -n in $BINDEP_PKGS
            ;;
        centos)
            sudo yum install -y $BINDEP_PKGS
            ;;
        ubuntu|debian)
            sudo apt-get update
            DEBIAN_FRONTEND=noninteractive \
                sudo apt-get -q --option "Dpkg::Options::=--force-confold" \
                --assume-yes install $BINDEP_PKGS
            ;;
    esac
fi

sudo pip install ansible
