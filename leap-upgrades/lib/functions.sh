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

## Functions -----------------------------------------------------------------
function notice {
  echo -e "[+]\t\033[1;32m${1}\033[0m"
}

function warning {
  echo -e "[-]\t\033[1;33m${1}\033[0m"
}

function failure {
  echo -e '[!]'"\t\033[1;31m${1}\033[0m"
}

function tag_leap_success {
  notice "LEAP ${1} success"
  touch "/opt/leap42/openstack-ansible-${1}.leap"
}

function run_lock {
  set +e
  run_item="${RUN_TASKS[$1]}"
  file_part="$(echo ${run_item} | sed 's/\s/-/g')"

  if [ ! -d  "/etc/openstack_deploy/upgrade-leap" ]; then
      mkdir -p "/etc/openstack_deploy/upgrade-leap"
  fi

  upgrade_marker_file=$(basename "${file_part}")
  upgrade_marker="/etc/openstack_deploy/upgrade-leap/$upgrade_marker_file.complete"

  if [ ! -f "$upgrade_marker" ];then
    # note(sigmavirus24): use eval so that we properly turn strings like
    # "/tmp/fix_container_interfaces.yml || true"
    # into a command, otherwise we'll get an error that there's no playbook
    # named ||
    eval "openstack-ansible $2"
    playbook_status="$?"
    notice "Ran: $run_item"

    if [ "$playbook_status" == "0" ];then
      RUN_TASKS=("${RUN_TASKS[@]/$run_item}")
      touch "${upgrade_marker}"
      notice "$run_item has been marked as success at ${upgrade_marker}"
    else
      FAILURES_LIST=$(seq $1 $((${#RUN_TASKS[@]} - 1)))
      failure "******************** failure ********************"
      failure "The upgrade script has encountered a failure."
      failure "Failed on task \"$run_item\""
      failure "Execute the remaining tasks manually:"
      # NOTE:
      # List the remaining, in-completed tasks from the tasks array.
      # Using seq to generate a sequence which starts from the spot
      # where previous exception or failures happened.
      # run the tasks in order.
      for item in ${FAILURES_LIST}; do
        if [ -n "${RUN_TASKS[$item]}" ]; then
          warning "openstack-ansible ${RUN_TASKS[$item]}"
        fi
      done
      failure "******************** failure ********************"
      exit 99
    fi
  else
    RUN_TASKS=("${RUN_TASKS[@]/$run_item.*}")
  fi
  set -e
}

function system_bootstrap {
    if [[ -d "/opt/ansible-runtime" ]]; then
      rm -rf "/opt/ansible-runtime"
    else
      # There are several points in time where pip may have been busted or creating dist-info
      #  directories incorrectly. This command simply mops those bits up when the
      #  ansible-runtime venv does not exist.
      find /usr/local/lib/python2.7/dist-packages -name '*.dist-info' -exec rm -rf {} \; || true
    fi

    # If there's a pip.conf file, move it out of the way
    if [[ -f "${HOME}/.pip/pip.conf" ]]; then
      mv "${HOME}/.pip/pip.conf" "${HOME}/.pip/pip.conf.original"
    fi

    # If ansible is already installed, uninstall it.
    while pip uninstall -y ansible > /dev/null; do
      notice "Removed System installed Ansible"
    done

    pushd "$1"
      # Install the releases global requirements
      if [[ -f "global-requirement-pins.txt" ]]; then
        pip install --upgrade --isolated --force-reinstall --requirement global-requirement-pins.txt
      fi

      # Install ansible for system migrations
      scripts/bootstrap-ansible.sh
    popd
}

function pre_flight {
    ## Pre-flight Check ----------------------------------------------------------
    # Clear the screen and make sure the user understands whats happening.
    clear

    # Notify the user.
    warning "This script will perform a LEAP upgrade from Juno to Newton."
    warning "Once you start the upgrade there's no going back."
    warning "**Note, this is an OFFLINE upgrade**"
    notice "If you want to run the upgrade in parts please exit this script to do so."
    warning "Are you ready to perform this upgrade now?"

    # Confirm the user is ready to upgrade.
    read -p 'Enter "YES" to continue or anything else to quit: ' UPGRADE
    if [ "${UPGRADE}" == "YES" ]; then
      notice "Running LEAP Upgrade"
    else
      exit 99
    fi

    mkdir -p /opt/leap42/venvs

    pushd /opt/leap42
      # Using this lookup plugin because it allows us to compile exact service releaes and build a complete venv from it
      wget https://raw.githubusercontent.com/openstack/openstack-ansible-plugins/e069d558b3d6ae8fc505d406b13a3fb66201a9c7/lookup/py_pkgs.py -O py_pkgs.py
      chmod +x py_pkgs.py
    popd

    # If the lxc backend store was not set halt and instruct the user to set it. In Juno we did more to detect the backend storage
    #  size than we do in later releases. While the auto-detection should still work it's best to have the deployer set the value
    #  desired before moving forward.
    if [[ -d "/etc/rpc_deploy" ]]; then
      CONFIG_DIR="/etc/rpc_deploy"
    else
      CONFIG_DIR="/etc/openstack_deploy"
    fi
    if ! grep -qwrn "^lxc_container_backing_store" $CONFIG_DIR; then
      failure "ERROR: 'lxc_container_backing_store' is unset leading to an ambiguous container backend store."
      failure "Before continuing please set the 'lxc_container_backing_store' in your user_variables.yml file."
      failure "Valid options are 'dir', 'lvm', and 'overlayfs'".
      exit 99
    fi

    # Install liberasurecode-dev which will be used in the venv creation process
    if ! grep -n ^ /etc/apt/sources.list /etc/apt/sources.list.d/* | grep -qw "backports"; then
      failure "The trusty backports repo has not been enabled on this host."
      exit 99
    fi
    apt-get update > /dev/null
    apt-get -y install liberasurecode-dev > /dev/null

    # Upgrade pip if it's needed. This will re-install pip using the constraints and then
    #  re-install all of the remaining requirements as needed.
    if dpkg --compare-versions "$(pip --version  | awk '{print $2}')" "lt" "9.0.1"; then
      wget https://raw.githubusercontent.com/pypa/get-pip/430ba37776ae2ad89f794c7a43b90dc23bac334c/get-pip.py -O /opt/get-pip.py
      rm -rf /usr/local/lib/python2.7/dist-packages/{setuptools,wheel,pip,distutils,packaging}*
      python /opt/get-pip.py --constraint "${SYSTEM_PATH}/lib/upgrade-requirements.txt" --force-reinstall --upgrade --isolated
      pip install --requirement "${SYSTEM_PATH}/lib/upgrade-requirements.txt" --upgrade --isolated
    fi

    if [[ -d "/opt/ansible-runtime" ]]; then
      rm -rf "/opt/ansible-runtime"
    fi

    virtualenv /opt/ansible-runtime
    PS1="\\u@\h \\W]\\$" . "/opt/ansible-runtime/bin/activate"
    pip install "ansible==1.9.3" "netaddr>=0.7.12,<=0.7.13" --force-reinstall --upgrade --isolated
    deactivate
}

function run_items {
    ### Run system upgrade processes
    pushd "$1"
      if [[ -e "playbooks" ]]; then
        PB_DIR="playbooks"
      elif [[ -e "rpc_deployment" ]]; then
        PB_DIR="rpc_deployment"
      else
        failure "No known playbook directory found"
        exit 99
      fi

      # Before running anything execute inventory to ensure functionality
      if [[ -f "${PB_DIR}/inventory/dynamic_inventory.py" ]]; then
        python "${PB_DIR}/inventory/dynamic_inventory.py" > /dev/null
      fi

      pushd ${PB_DIR}
        # Run the tasks in order
        for item in ${!RUN_TASKS[@]}; do
          run_lock $item "${RUN_TASKS[$item]}"
        done
      popd
    popd
}

function clone_release {
    # If the git directory is not present clone the source into place at the given directory
    if [[ ! -d "/opt/leap42/openstack-ansible-base/.git" ]]; then
      git clone https://git.openstack.org/openstack/openstack-ansible "/opt/leap42/openstack-ansible-base"
    fi

    # The clone release function clones everything from upstream into the leap42 directory as needed.
    if [[ ! -d "/opt/leap42/openstack-ansible-$1" ]]; then
      cp -R "/opt/leap42/openstack-ansible-base" "/opt/leap42/openstack-ansible-$1"
    fi

    # Once cloned the method will perform a checkout of the branch, tag, or commit.
    #  Enter the clone directory and checkout the given branch, If the given checkout has an
    #  "ignore-changes.marker" file present the checkout will be skipped.
    pushd "/opt/leap42/openstack-ansible-$1"
      if [[ -f "ignore-changes.marker" ]]; then
        git clean -qfdx
        git fetch --all
        git checkout "$1"
      fi
    popd
}

function link_release {
    ### Because there are multiple releases that we'll need to run through to get the system up-to-date
    ###  and because the "/opt/openstack-ansible" dir must exist, this function will move any existing
    ###  "/opt/openstack-ansible" dir to a backup dir and then link our multiple releases into the
    ###  standard repository dir as needed.
    if [[ -d "/opt/openstack-ansible" ]]; then
      mv "/opt/openstack-ansible" "/opt/openstack-ansible.bak"
    fi
    ln -sf "$1" "/opt/openstack-ansible"
}

function run_venv_prep {
    # If the ansible-playbook command is not found this will bootstrap the system
    if ! which ansible-playbook; then
      pushd "/opt/leap42/openstack-ansible-$1"
        bash scripts/bootstrap-ansible.sh  # install ansible because it's not currently ready
      popd
    fi

    if [[ -e "/etc/rpc_deploy" ]]; then
      PB_DIR="/opt/leap42/openstack-ansible-${JUNO_RELEASE}/rpc_deployment"
    else
      PB_DIR="/opt/leap42/openstack-ansible-${KILO_RELEASE}/playbooks"
    fi

    pushd "${PB_DIR}"
      openstack-ansible "${UPGRADE_UTILS}/venv-prep.yml" -e "venv_tar_location=/opt/leap42/venvs/openstack-ansible-$1.tgz"
    popd
}

function build_venv {
    ### The venv build is done using a modern version of the py_pkgs plugin which collects all versions of
    ###  the OpenStack components from a given release. This creates 1 large venv per migratory release.
    # If the venv archive exists delete it.
    if [[ ! -f "/opt/leap42/venvs/openstack-ansible-$1.tgz" ]]; then
      # Create venv
      virtualenv --never-download --always-copy "/opt/leap42/venvs/openstack-ansible-$1"
      PS1="\\u@\h \\W]\\$" . "/opt/leap42/venvs/openstack-ansible-$1/bin/activate"
      pip install --upgrade --isolated --force-reinstall

      # Modern Ansible is needed to run the package lookups
      pip install --isolated "ansible==2.1.1.0" "mysql-python" "vine" "pymysql"

      # Get package dump from the OSA release
      PKG_DUMP=$(python /opt/leap42/py_pkgs.py /opt/leap42/openstack-ansible-$1/playbooks/defaults/repo_packages)
      PACKAGES=$(python <<EOC
import json
packages = json.loads("""$PKG_DUMP""")
remote_packages = packages[0]['remote_packages']
print(' '.join([i for i in remote_packages if 'openstack' in i]))
EOC)
      pip install --isolated $PACKAGES
      deactivate

      # Create venv archive
      pushd /opt/leap42/venvs
        find "openstack-ansible-$1" -name '*.pyc' -exec rm {} \;
        tar -czf "openstack-ansible-$1.tgz" "openstack-ansible-$1"
      popd
    else
      notice "The venv \"/opt/leap42/venvs/openstack-ansible-$1.tgz\" already exists. If you need to recreate this venv, delete it."
    fi
    run_venv_prep "$1"
}

function get_venv {
  # Attempt to prefetch a venv archive before building it.
  if ! wget "${VENV_URL}/openstack-ansible-$1.tgz" "/opt/leap42/venvs/openstack-ansible-$1.tgz" > /dev/null; then
    build_venv "$1"
  else
    run_venv_prep "$1"
  fi
}
