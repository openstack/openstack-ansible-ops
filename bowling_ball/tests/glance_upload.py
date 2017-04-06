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
from glanceclient import Client
from glanceclient import exc
from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneauth1.exceptions.connection import ConnectFailure
from keystoneauth1.exceptions.http import BadGateway
from keystoneauth1.exceptions.http import InternalServerError
from keystoneclient.v3 import client as key_client
import logging
import os
import sys
import tempfile
import time

logger = logging.getLogger(__name__)


def configure_logging():
    logger.setLevel(logging.INFO)
    console = logging.StreamHandler()
    logfile = logging.FileHandler('/var/log/glance_query.log', 'a')

    console.setLevel(logging.INFO)
    logfile.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    # Make sure we're using UTC for everything.
    formatter.converter = time.gmtime

    console.setFormatter(formatter)
    logfile.setFormatter(formatter)

    logger.addHandler(console)
    logger.addHandler(logfile)


configure_logging()


def get_session():
    auth_url = os.environ['OS_AUTH_URL']
    password = os.environ['OS_PASSWORD']
    auth = v3.Password(auth_url=auth_url, username="admin",
                       password=password, project_name="admin",
                       user_domain_id="default",
                       project_domain_id="default")
    sess = session.Session(auth=auth)
    return sess


def get_keystone_client(session):
    return key_client.Client(session=session)


def get_glance_endpoint(keystone):
    """Get the glance admin endpoint

    Because we don't want to set up SSL handling, use the plain HTTP
    endpoints.
    """
    service_id = keystone.services.find(name='glance')
    glance_endpoint = keystone.endpoints.list(service=service_id,
                                              interface='admin')[0]
    # The glance client wants the URL, not the keystone object
    return glance_endpoint.url

sess = get_session()
keystone = get_keystone_client(sess)
endpoint = get_glance_endpoint(keystone)

# Has to be a tuple for python syntax reasons.
exc_list = (ConnectFailure, InternalServerError, BadGateway,
            exc.CommunicationError)

disconnected = None
try:
    while True:
        try:
            time.sleep(1)

            # make a bogus file to give to glance.
            temp_file = tempfile.TemporaryFile()
            temp_file.write(os.urandom(1024 * 1024))
            temp_file.seek(0)

            start_time = datetime.datetime.now()

            glance = Client(version='2', endpoint=endpoint, session=sess)
            image = glance.images.create(name="Rolling test",
                                         disk_format="raw",
                                         container_format="bare")
            try:
                glance.images.upload(image.id, temp_file)
            except exc.HTTPInternalServerError:
                logger.error("Failed to upload")
            finally:
                glance.images.delete(image.id)
                temp_file.close()

            end_time = datetime.datetime.now()

            if disconnected:
                dis_delta = end_time - disconnected
                disconnected = None
                logger.info("Reconnect {}s".format(dis_delta.total_seconds()))

            delta = end_time - start_time
            logger.info("Image made/deleted {}s".format(delta.total_seconds()))
        except exc_list:
            if not disconnected:
                disconnected = datetime.datetime.now()
except KeyboardInterrupt:
    sys.exit()
