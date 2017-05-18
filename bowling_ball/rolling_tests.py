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
from keystoneauth1.exceptions.http import BadGateway
from keystoneauth1.exceptions.http import InternalServerError
from keystoneclient.v3 import client as key_client
import logging
import os
import sys
import time
from glanceclient import Client
from glanceclient import exc
import tempfile

logger = logging.getLogger(__name__)


def configure_logging(service):
    """Configure a stream and file log for a given service

    :param: service - name of service for log file.
            generates `/var/log/{service_name}_query.log`
    """
    logger.setLevel(logging.INFO)
    console = logging.StreamHandler()
    logfile = logging.FileHandler('/var/log/keystone_query.log', 'a')

    console.setLevel(logging.INFO)
    logfile.setLevel(logging.INFO)

    formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    # Make sure we're using UTC for everything.
    formatter.converter = time.gmtime

    console.setFormatter(formatter)
    logfile.setFormatter(formatter)

    logger.addHandler(console)
    logger.addHandler(logfile)


def keystone_test(logger):
    configure_logging('keystone')

    auth_url = os.environ['OS_AUTH_URL']
    password = os.environ['OS_PASSWORD']

    auth = v3.Password(auth_url=auth_url, username="admin",
                       password=password, project_name="admin",
                       user_domain_id="default", project_domain_id="default")
    sess = session.Session(auth=auth)
    keystone = key_client.Client(session=sess)
    test_list = keystone.projects.list()
    if test_list:
        msg = "New project list."
    else:
        msg = "Failed to get project list"
    return msg


def test_loop(test_function):
    """Main loop to execute tests

    Executes and times interactions with OpenStack services to gather timing
    data.
    :param: test_function - function object that performs some action
            against an OpenStack service API.
    """
    disconnected = None
    # Has to be a tuple for python syntax reasons.
    # This is currently the set needed for glance; should probably
    # provide some way of letting a test say which exceptions should
    # be caught for a service.
    exc_list = (ConnectFailure, InternalServerError, BadGateway,
                exc.CommunicationError, exc.HTTPInternalServerError)
    try:
        while True:
            try:
                # Pause for a bit so we're not generating more data than we
                # can handle
                time.sleep(1)
                start_time = datetime.datetime.now()

                # Let the test function report it's own errors
                msg = test_function(logger)

                end_time = datetime.datetime.now()

                if disconnected:
                    dis_delta = end_time - disconnected
                    disconnected = None
                    logger.info("Reconnect {}s".format(
                                dis_delta.total_seconds()))

                delta = end_time - start_time

                logger.info("{}s {}s.".format(msg, delta.total_seconds()))
            except (exc_list):
                if not disconnected:
                    disconnected = datetime.datetime.now()
    except KeyboardInterrupt:
        sys.exit()


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


def glance_test(logger):
    configure_logging('glance')
    # make a bogus file to give to glance.

    sess = get_session()
    keystone = get_keystone_client(sess)
    endpoint = get_glance_endpoint(keystone)

    temp_file = tempfile.TemporaryFile()
    temp_file.write(os.urandom(1024 * 1024))
    temp_file.seek(0)

    glance = Client(version='2', endpoint=endpoint, session=sess)
    image = glance.images.create(name="Rolling test",
                                 disk_format="raw",
                                 container_format="bare")
    try:
        glance.images.upload(image.id, temp_file)
    except exc.HTTPInternalServerError:
        # TODO: set msg and error type instead.
        logger.error("Failed to upload")
        return
    finally:
        glance.images.delete(image.id)
        temp_file.close()

    msg = "Image created and deleted."
    return msg

if __name__ == "__main__":
    test_loop(glance_test)
