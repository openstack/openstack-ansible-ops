from openstack import connection
import os
import datetime
import time
import logging
import sys

logger = logging.getLogger(__name__)


def configure_logging():
    logger.setLevel(logging.INFO)
    console = logging.StreamHandler()
    logfile = logging.FileHandler('/var/log/nova_query.log', 'a')

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


auth_url = os.environ['OS_AUTH_URL']
password = os.environ['OS_PASSWORD']
username = os.environ['OS_USERNAME']
region = os.environ['OS_REGION_NAME']
project_name = os.environ['OS_PROJECT_NAME']
project_domain_name = os.environ['OS_PROJECT_DOMAIN_NAME']
user_domain_name = os.environ['OS_USER_DOMAIN_NAME']

auth_args = {
    'auth_url': auth_url,
    'project_name': project_name,
    'username': username,
    'password': password,
    'project_domain_name': project_domain_name,
    'user_domain_name': user_domain_name,
    'verify': False,
}

disconnected = None
try:
    while True:
        try:
            # Pause for a bit so we're not generating more data than we
            # can handle
            time.sleep(1)
            start_time = datetime.datetime.now()
            conn = connection.Connection(**auth_args)
            server = conn.compute.servers()

            end_time = datetime.datetime.now()

            if disconnected:
                dis_delta = end_time - disconnected
                disconnected = None
                logger.info("Reconnect {}s".format(dis_delta.total_seconds()))

            delta = end_time - start_time

            logger.info("New list: {}s.".format(delta.total_seconds()))
        except ():
            if not disconnected:
                disconnected = datetime.datetime.now()
except KeyboardInterrupt:
    sys.exit()
