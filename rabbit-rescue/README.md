# Rabbit-Rescue

Use this script to rebuild the vhosts and permissions in Rabbitmq in case it gets borked. <br>*(Don't even ask how I managed to do this...)*

This script is loosely based on informatoin gleaned from [this RedHat article](https://access.redhat.com/articles/1167113), and was added to this repo based on [this conversation](http://eavesdrop.openstack.org/irclogs/%23openstack-ansible/%23openstack-ansible.2020-03-11.log.html). <br>Apparently I'm not the only one who has inadvertently destroyed their RabbitMQ installation, so this may be helpful to others in the future.

Note: For clustered installations, this needs to run only on a single node.

## Usage:

- Clone this repo into /opt on your deployment host.

- Edit the Bash array `all_services` and populate with the services you were using in RabbitMQ.

- Populate the service secrets with the information found in your `/etc/openstack_deploy/user_secrets.yml` file.
  - _(this is quite possibly something we could try to do automatically in a future update)_

- Execute this from the deployment host, targeting one of your RabbitMQ containers:
  - ```
    # cd /opt/openstack-ansible
    # ansible rabbit_mq_container -m copy -a 'src=/opt/openstack-ops/rabbit-rescue/rabbit-rescue.sh dest=/tmp/rabbit-rescue.sh mode=preserve'
    # ansible rabbit_mq_container -m shell -a '/tmp/rabbit-rescue.sh'
    ```
  - Profit!

## Alternative Usage:

- Copy the script file down to one of your RabbitMQ Containers.

- Edit the contents per the above instructions, and execute it.