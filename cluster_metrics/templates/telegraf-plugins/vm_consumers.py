#!/bin/python
#
# Copyright 2016, Rackspace US, Inc.
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

import collections

from openstack import connection as os_conn


OS_AUTH_ARGS = {
    'auth_url': '{{ keystone_service_internalurl }}',
    'project_name': '{{ keystone_admin_tenant_name }}',
    'user_domain_name': '{{ openrc_os_domain_name }}',
    'project_domain_name': '{{ openrc_os_domain_name }}',
    'username': '{{ keystone_admin_user_name }}',
    'password': '{{ keystone_auth_admin_password }}',
}

OS_CONNECTION = {'conn': None}


def line_return(collection, metric_name):
    system_states_return = '%s ' % metric_name
    for key, value in collection.items():
        system_states_return += '%s=%s,' % (key.replace(' ', '_'), value)
    else:
        system_states_return = system_states_return.rstrip(',')
    return system_states_return


def _connect():
    if OS_CONNECTION['conn']:
        return OS_CONNECTION['conn']
    else:
        OS_CONNECTION['conn'] = os_conn.Connection(**OS_AUTH_ARGS)
        return OS_CONNECTION['conn']


def get_consumers():
    conn = _connect()
    _consumers = list()
    projects = conn.identity.projects()
    for project in projects:
        if project['description'].lower() != 'heat stack user project':
            _consumers.append(project)
    return _consumers


def get_consumer_limits(consumer_id):
    conn = _connect()
    url = conn.compute.session.get_endpoint(
        interface='internal',
        service_type='compute'
    )
    quota_data = conn.compute.session.get(
        url + '/os-quota-sets/' + consumer_id
    )
    quota_data = quota_data.json()
    return quota_data['quota_set']


def get_consumer_usage():
    conn = _connect()
    tenant_kwargs = {'all_tenants': True, 'limit': 5000}
    return conn.compute.servers(details=True, **tenant_kwargs)


def get_flavors():
    conn = _connect()
    flavor_cache = dict()
    for flavor in conn.compute.flavors():
        entry = flavor_cache[flavor['id']] = dict()
        entry['ram'] = flavor['ram']
        entry['cores'] = flavor['vcpus']
        entry['disk'] = flavor['disk']
    return flavor_cache


def main():
    return_data = list()
    consumer_quota_instance = dict()
    consumer_quota_cores = dict()
    consumer_quota_ram = dict()
    consumer_used_instances = collections.Counter()
    consumer_used_cores = collections.Counter()
    consumer_used_ram = collections.Counter()
    consumer_used_disk = collections.Counter()
    consumer_quota_totals = dict()

    flavor_cache = get_flavors()
    consumer_id_cache = dict()
    for consumer in get_consumers():
        consumer_name = consumer['name']
        consumer_id = consumer['id']
        _quota = get_consumer_limits(consumer_id)
        consumer_id_cache[consumer_id] = consumer_name
        consumer_quota_instance[consumer_name] = int(_quota['instances'])
        consumer_quota_cores[consumer_name] = int(_quota['cores'])
        consumer_quota_ram[consumer_name] = int(_quota['ram'])

    for used_instance in get_consumer_usage():
        consumer_name = consumer_id_cache[used_instance['tenant_id']]
        consumer_used_instances[consumer_name] += 1
        consumer_used_cores[consumer_name] += \
            int(flavor_cache[used_instance['flavor']['id']]['cores'])
        consumer_used_ram[consumer_name] += \
            int(flavor_cache[used_instance['flavor']['id']]['ram'])
        consumer_used_disk[consumer_name] += \
            int(flavor_cache[used_instance['flavor']['id']]['disk'])

    consumer_quota_totals['total_quota_instance'] = sum(
        consumer_quota_instance.values()
    )
    consumer_quota_totals['total_quota_cores'] = sum(
        consumer_quota_cores.values()
    )
    consumer_quota_totals['total_quota_ram'] = sum(
        consumer_quota_ram.values()
    )

    consumer_quota_totals['total_used_instances'] = sum(
        consumer_used_instances.values()
    )
    consumer_quota_totals['total_used_cores'] = sum(
        consumer_used_cores.values()
    )
    consumer_quota_totals['total_used_ram'] = sum(
        consumer_used_ram.values()
    )
    consumer_quota_totals['total_used_disk'] = sum(
        consumer_used_disk.values()
    )

    return_data.append(
        line_return(
            collection=consumer_quota_instance,
            metric_name='consumer_quota_instance'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_quota_cores,
            metric_name='consumer_quota_cores'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_quota_ram,
            metric_name='consumer_quota_ram'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_used_instances,
            metric_name='consumer_used_instances'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_used_cores,
            metric_name='consumer_used_cores'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_used_ram,
            metric_name='consumer_used_ram'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_used_disk,
            metric_name='consumer_used_disk'
        )
    )

    return_data.append(
        line_return(
            collection=consumer_quota_totals,
            metric_name='consumer_quota_totals'
        )
    )
    for item in return_data:
        print(item)

if __name__ == '__main__':
    main()
