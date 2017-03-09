#!/usr/bin/env python
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
#
# (c) 2017, Nolan Brubaker <nolan.brubaker@rackspace.com>

import argparse
import json
import os
import subprocess
import sys
import time

CONF_DIR = os.path.join('/', 'etc', 'openstack_deploy')
INVENTORY_FILE = os.path.join(CONF_DIR, 'openstack_inventory.json')
CONF_FILE = os.path.join(CONF_DIR, 'openstack_user_config.yml')
PLAYBOOK_DIR = os.path.join('/', 'opt', 'openstack_ansible', 'playbooks')

STOP_TEMPLATE = 'ansible -i inventory -m shell -a\
        "lxc-stop -n {container}" {host}'
START_TEMPLATE = 'ansible -i inventory -m shell -a\
        "lxc-start -dn {container}" {host}'


def args(arg_list):
    parser = argparse.ArgumentParser(
        usage='%(prog)s',
        description='OpenStack-Ansible Rolling Update Simulator',
        epilog='Licensed "Apache 2.0"')

    parser.add_argument(
        '-s',
        '--service',
        help='Name of the service to rolling restart.',
        required=True,
        default=None,
    )

    parser.add_argument(
        '-w',
        '--wait',
        help=("Number of seconds to wait between stopping and starting. "
              "Default: 120"),
        default=120,
    )

    return vars(parser.parse_args(arg_list))


def read_inventory(inventory_file):
    """Parse inventory file into a python dictionary"""
    with open(inventory_file, 'r') as f:
        inventory = json.load(f)
    return inventory


def get_similar_groups(target_group, inventory):
    """
    Find group suggestions
    """
    suggestions = []
    for key in inventory.keys():
        if target_group in key:
            suggestions.append(key)
    return suggestions


def get_containers(target_group, inventory):
    """Get container names in the relevant group"""

    group = inventory.get(target_group, None)

    if group is None:
        groups = get_similar_groups(target_group, inventory)
        print("No group {} found.".format(target_group))
        if groups:
            print("Maybe try one of these:")
            print("\n".join(groups))
        sys.exit(1)

    containers = group['hosts']
    containers.sort()
    return containers


def rolling_restart(containers, inventory, wait=120):
    """Restart containers in numerical order, one at a time.

    wait is the number of seconds to wait between stopping and starting a
    container
    """
    for container in containers:
        host = inventory['_meta']['hostvars'][container]['physical_host']

        stop_cmd = STOP_TEMPLATE.format(container=container, host=host)
        print("Stopping {container}".format(container=container))
        subprocess.check_call(stop_cmd, shell=True)

        time.sleep(wait)

        start_cmd = START_TEMPLATE.format(container=container, host=host)
        subprocess.check_call(start_cmd, shell=True)
        print("Started {container}".format(container=container))


def main():
    all_args = args(sys.argv[1:])
    service = all_args['service']
    wait = all_args['wait']

    inventory = read_inventory(INVENTORY_FILE)
    containers = get_containers(service, inventory)

    rolling_restart(containers, inventory, wait)

if __name__ == "__main__":
    main()
