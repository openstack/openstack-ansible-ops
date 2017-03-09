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

import datetime
from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneauth1.exceptions.connection import ConnectFailure
from keystoneauth1.exceptions.http import InternalServerError
from keystoneclient.v3 import client
import os
import sys
import time

auth_url = os.environ['OS_AUTH_URL']
password = os.environ['OS_PASSWORD']

auth = v3.Password(auth_url=auth_url, username="admin",
                   password=password, project_name="admin",
                   user_domain_id="default", project_domain_id="default")

disconnected = None
try:
    while True:
        try:
            # Pause for a bit so we're not generating more data than we
            # can handle
            time.sleep(1)
            start_time = datetime.datetime.now()

            sess = session.Session(auth=auth)
            keystone = client.Client(session=sess)
            keystone.projects.list()

            end_time = datetime.datetime.now()

            if disconnected:
                dis_delta = end_time - disconnected
                disconnected = None
                print("Reconnect {}s".format(dis_delta.total_seconds()))

            delta = end_time - start_time

            print("New list: {]s.".format(delta.total_seconds()))
        except (ConnectFailure, InternalServerError):
            if not disconnected:
                disconnected = datetime.datetime.now()
except KeyboardInterrupt:
    sys.exit()
