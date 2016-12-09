#!/usr/bin/env python
# Copyright 2016, Intel US, Inc.
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
# This script calls the cinder API and gathers the volume group capacity
# information and outputs to Influx Protocol Line format

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


def _connect():
    if OS_CONNECTION['conn']:
        return OS_CONNECTION['conn']
    else:
        OS_CONNECTION['conn'] = os_conn.Connection(**OS_AUTH_ARGS)
        return OS_CONNECTION['conn']


def main():
    pool_data = dict()
    conn = _connect()
    url = conn.block_store.session.get_endpoint(
        interface='internal',
        service_type='volume'
    )
    block_store_data_raw = conn.block_store.session.get(
        url + '/scheduler-stats/get_pools?detail=True'
    )
    block_store_data = block_store_data_raw.json()

    total_capacity_gb = 0
    free_capacity_gb = 0
    for item in block_store_data.get('pools', []):
        name = item.get('name')
        if name:
            cap = item['capabilities']
            _total_capacity_gb = float(cap.get('total_capacity_gb', 0))
            _free_capacity_gb = float(cap.get('free_capacity_gb', 0))
            pool_name = cap.get('pool_name')
            if pool_name in pool_data:
                pool = pool_data[pool_name]
            else:
                pool = pool_data[pool_name] = dict()
            pool[name] = 100 * _free_capacity_gb / _total_capacity_gb
            free_capacity_gb += _free_capacity_gb
            total_capacity_gb += _total_capacity_gb

    finalized_data = dict()
    for key, value in pool_data.items():
        data = finalized_data['cinder,pool=%s' % key] = list()
        for k, v in value.items():
            data.append('%s=%s' % (k.replace(' ', '_'), v))

    for key, value in finalized_data.items():
        print('%s %s' % (key, ','.join(value)))

    tup = 100 * free_capacity_gb / total_capacity_gb
    totals = 'cinder_totals cinder_total_percent_used=%s' % tup
    print(totals)

if __name__ == '__main__':
    main()
