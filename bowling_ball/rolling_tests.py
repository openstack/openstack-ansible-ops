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

# Necessary for accurate failure rate calculation
from __future__ import division
import argparse
import datetime
from keystoneauth1.identity import v3
from keystoneauth1 import session
from keystoneclient.v3 import client as key_client
import logging
import os
import signal
import sys
import time
from glanceclient import Client
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


class ServiceTest(object):
    def pre_test(self, *args, **kwargs):
        """Any actions that need to be taken before starting the timer

        These actions will run inside the test loop, but before marking a
        start time.

        This might include creating a local resource, such as a file to upload
        to Glance, Cinder, or Swift.

        """
        raise NotImplementedError

    def run(self):
        """Run the main test, within the timing window.

        This test run should actually create and query a resource.
        """
        raise NotImplementedError

    def post_test(self):
        """Any post-test clean up work that needs to be done and not timed."""
        raise NotImplementedError

    def configure_logger(self, logger):
        """Configure a stream and file log for a given service

        :param: service - name of service for log file.
                generates `/var/log/{service_name}_query.log`
        :param: logger - logger to be configure for the test.
                Filename will be based on the test's `service_name`
                property
        """
        logger.setLevel(logging.INFO)
        console = logging.StreamHandler()
        filename = '/var/log/{}_rolling.log'.format(self.service_name)
        logfile = logging.FileHandler(filename, 'a')

        console.setLevel(logging.INFO)
        logfile.setLevel(logging.INFO)

        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s')
        # Make sure we're using UTC for everything.
        formatter.converter = time.gmtime

        console.setFormatter(formatter)
        logfile.setFormatter(formatter)

        logger.addHandler(console)
        logger.addHandler(logfile)

    # This is useful to a lot of tests, so implement it here for re-use
    def get_session(self):
        auth_url = os.environ['OS_AUTH_URL']
        password = os.environ['OS_PASSWORD']
        auth = v3.Password(auth_url=auth_url, username="admin",
                           password=password, project_name="admin",
                           user_domain_id="default",
                           project_domain_id="default")
        sess = session.Session(auth=auth)
        return sess

    def get_keystone_client(self, session):
        return key_client.Client(session=session)


class KeystoneTest(ServiceTest):
    service_name = 'keystone'
    description = 'Obtain a token then a project list to validate it worked'

    def run(self):

        auth_url = os.environ['OS_AUTH_URL']
        password = os.environ['OS_PASSWORD']

        auth = v3.Password(auth_url=auth_url, username="admin",
                           password=password, project_name="admin",
                           user_domain_id="default",
                           project_domain_id="default")

        sess = session.Session(auth=auth)
        keystone = key_client.Client(session=sess)
        keystone.projects.list()
        msg = "Project list retrieved"
        return msg


class GlanceTest(ServiceTest):
    service_name = 'glance'
    description = 'Upload and delete a 1MB file'

    def pre_test(self):
        # make a bogus file to give to glance.
        self.temp_file = tempfile.TemporaryFile()
        self.temp_file.write(os.urandom(1024 * 1024))
        self.temp_file.seek(0)

    def run(self):
        sess = self.get_session()
        keystone = self.get_keystone_client(sess)
        endpoint = self.get_glance_endpoint(keystone)

        glance = Client(version='2', endpoint=endpoint, session=sess)
        image = glance.images.create(name="Rolling test",
                                     disk_format="raw",
                                     container_format="bare")
        glance.images.upload(image.id, self.temp_file)
        glance.images.delete(image.id)
        self.temp_file.close()

        msg = "Image created and deleted."
        return msg

    def get_glance_endpoint(self, keystone):
        """Get the glance admin endpoint

        Because we don't want to set up SSL handling, use the plain HTTP
        endpoints.
        """
        service_id = keystone.services.find(name='glance')
        glance_endpoint = keystone.endpoints.list(service=service_id,
                                                  interface='admin')[0]
        # The glance client wants the URL, not the keystone object
        return glance_endpoint.url


class TestRunner(object):
    """Run a test in a loop, with the option to gracefully exit"""
    stop_now = False

    def __init__(self):
        signal.signal(signal.SIGINT, self.prep_exit)
        signal.signal(signal.SIGTERM, self.prep_exit)
        self.failures = 0
        self.attempts = 0

    def prep_exit(self, signum, frame):
        self.stop_now = True
        logger.info("Received signal, stopping")

    def write_summary(self):
        percentage = (self.failures / self.attempts) * 100
        # Display minimum of 2 digits, but don't use decimals.
        logger.info("%2.0f%% failure rate", percentage)

    def test_loop(self, test):
        """Main loop to execute tests

        Executes and times interactions with OpenStack services to gather
        timing data.

        Execution can be ended by sending SIGINT or SIGTERM and the running
        test will finish.

        :param: test - on object that performs some action
                against an OpenStack service API.
        """
        disconnected = None
        while True:
            self.attempts += 1
            try:
                # Pause for a bit so we're not generating more data than we
                # can handle
                time.sleep(1)

                try:
                    test.pre_test()
                except NotImplementedError:
                    pass

                start_time = datetime.datetime.now()

                # Let the test function report it's own errors
                msg = test.run()

                end_time = datetime.datetime.now()

                if disconnected:
                    dis_delta = end_time - disconnected
                    disconnected = None
                    logger.info("Reconnect {}s".format(
                                dis_delta.total_seconds()))

                delta = end_time - start_time

                logger.info("{} {}".format(msg, delta.total_seconds()))

                try:
                    test.post_test()
                except NotImplementedError:
                    pass

            # Catch all exceptions not handled by the tests themselves,
            # since we want to keep the loop running until explicitly stopped
            except Exception as e:
                self.failures += 1
                if not disconnected:
                    disconnected = datetime.datetime.now()
                # OpenStack API exceptions put their info in the 'details'
                # attribute; 'message' is the standard one.
                error_msg = getattr(e, 'details', e.message)
                logger.error("%s", error_msg)

            if self.stop_now:
                self.write_summary()
                sys.exit()


available_tests = {
    'keystone': KeystoneTest,
    'glance': GlanceTest,
}


def args(arg_list):

    parser = argparse.ArgumentParser(
        usage='%(prog)s',
        description='OpenStack activity simulators',
    )

    parser.add_argument(
        'test',
        help=("Name of test to execute, 'list' for a list of available"
              " tests")
    )
    return parser.parse_args(arg_list)


def find_test(test_name):
    if test_name in available_tests:
        return available_tests[test_name]
    elif test_name == "list":
        for key, test_class in available_tests.items():
            print("{} -> {}".format(key, test_class.description))
        sys.exit()
    else:
        print("Test named {} not found.".format(test_name))
        sys.exit()


if __name__ == "__main__":
    all_args = args(sys.argv[1:])

    target_test_class = find_test(all_args.test)

    target_test = target_test_class()
    target_test.configure_logger(logger)

    runner = TestRunner()

    runner.test_loop(target_test)
