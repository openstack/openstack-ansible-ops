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
import dbm
import json
import os
import tempfile

import MySQLdb as mysql
from MySQLdb.constants import FIELD_TYPE

from openstack import connection as os_conn
from openstack import exceptions as os_exp


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


def run_query(db_name, query):
    db = mysql.connect(
        db=db_name,
        read_default_file=os.path.expanduser('~/.my.cnf'),
        conv={FIELD_TYPE.LONG: int}
    )
    try:
        db.query(query)
        output = db.store_result()
    except mysql.OperationalError:
        SystemExit('DB Query failed')
    else:
        return output.fetch_row(maxrows=0)
    finally:
        db.close()


def _connect():
    if OS_CONNECTION['conn']:
        return OS_CONNECTION['conn']
    else:
        OS_CONNECTION['conn'] = os_conn.Connection(**OS_AUTH_ARGS)
        return OS_CONNECTION['conn']


def consumer_db(consumer_id):
    cdb = dbm.open(os.path.join(tempfile.gettempdir(), 'cdb.dbm'), 'c')
    try:
        project_name = cdb.get(consumer_id)
        if not project_name:
            conn = _connect()
            project_info = conn.identity.get_project(consumer_id)
            project_name = cdb[consumer_id] = project_info['name']
    except os_exp.ResourceNotFound:
        return 'UNKNOWN'
    else:
        return project_name
    finally:
        cdb.close()


def consumer_limits(consumer_id):
    conn = _connect()
    url = conn.compute.session.get_endpoint(
        interface='internal',
        service_type='compute'
    )
    quota_data = conn.compute.session.get(
        url + '/os-quota-sets/' + consumer_id
    )
    quota_data = quota_data.json()
    return quota_data['quota_set']['instances']


def main():
    return_data = []
    system_types = collections.Counter()
    system_types_used = collections.Counter()
    system_states = collections.Counter()
    system_used = collections.Counter()
    system_consumers = collections.Counter()
    system_consumer_limits = dict()
    system_consumer_map = dict()

    datas = run_query(
        db_name='{{ ironic_galera_database|default("ironic") }}',
        query="""select instance_uuid,properties,provision_state from nodes"""
    )

    for data in datas:
        x = json.loads(data[1])
        system_states[data[-1]] += 1

        node_consumed = data[0]
        system_used['total'] += 1
        if node_consumed:
            system_used['in_use'] += 1
        else:
            system_used['available'] += 1

        for capability in x['capabilities'].split(','):
            if capability.startswith('system_type'):
                system_type = capability.split(':')[-1]
                system_types[system_type] += 1
                if node_consumed:
                    system_types_used[system_type] += 1
                    _query = (
                        """select project_id from instances where uuid='%s'"""
                    ) % node_consumed
                    _project_id = run_query(
                        db_name='{{ nova_galera_database|default("nova") }}',
                        query=_query
                    )
                    project_id = _project_id[0][0]
                    project_name = consumer_db(project_id)
                    system_consumer_map[project_id] = project_name
                    system_consumers[project_name] += 1
                break

    if system_consumers:
        for key, value in system_consumer_map.items():
            system_consumer_limits[value] = consumer_limits(key)
        system_used['total_reserved'] = sum(system_consumer_limits.values())

    return_data.append(
        line_return(
            collection=system_types,
            metric_name='ironic_node_flavors'
        )
    )

    return_data.append(
        line_return(
            collection=system_types_used,
            metric_name='ironic_node_flavors_used'
        )
    )

    return_data.append(
        line_return(
            collection=system_states,
            metric_name='ironic_node_states'
        )
    )

    return_data.append(
        line_return(
            collection=system_used,
            metric_name='ironic_nodes_used'
        )
    )

    return_data.append(
        line_return(
            collection=system_consumers,
            metric_name='ironic_consumers'
        )
    )

    return_data.append(
        line_return(
            collection=system_consumer_limits,
            metric_name='ironic_consumer_limits'
        )
    )

    for item in return_data:
            print(item)

if __name__ == '__main__':
    main()
