Gather and visualize cluster wide metrics
#########################################
:date: 2017-12-01
:tags: openstack, ansible
:category: \*openstack, \*nix


About this repository
---------------------

This set of playbooks will deploy InfluxDB, Telegraf, and Kapacitor for the purpose of collecting
metrics on an OpenStack cluster.

Process
-------

Clone the OPS repo

.. code-block:: bash

    cd /opt
    git clone https://git.opendev.org/openstack/openstack-ansible-ops

Copy the env.d files into place

.. code-block:: bash

    cd openstack-ansible-ops/cluster_metrics
    cp etc/env.d/cluster_metrics.yml /etc/openstack_deploy/env.d/

Add the export to update the inventory file location

.. code-block:: bash

    export ANSIBLE_INVENTORY=/opt/openstack-ansible/playbooks/inventory/dynamic_inventory.py

If you are running the HA Proxy you should run the following playbook as well.

.. code-block:: bash

    openstack-ansible playbook-metrics-lb.yml

Create the containers

.. code-block:: bash

    openstack-ansible /opt/openstack-ansible/playbooks/lxc-containers-create.yml -e container_group=cluster-metrics

Install InfluxDB

.. code-block:: bash

    openstack-ansible playbook-influx-db.yml

Clone the Telegraf repo

.. code-block:: bash

    git clone https://github.com/mgrzybek/openstack-ansible-telegraf /etc/ansible/roles/openstack-ansible-telegraf

Install Influx Telegraf

If you wish to install telegraf and point it at a specific target, or list of targets, set the ``telegraf_output_influxdb_targets``
variable in the ``user_variables.yml`` file as a list containing all targets that telegraf should ship metrics to.

.. code-block:: bash

    openstack-ansible playbook-influx-telegraf.yml --forks 100

Install Kapacitor

.. code-block:: bash

   openstack-ansible playbook-kapacitor.yml


OpenStack Swift PRoxy Server Dashboard
--------------------------------------

Once the telegraf daemon is installed onto each host, the Swift
proxy-server can be instructed to forward statsd metrics to telegraf.
The following configuration enabled the metric generation and need to
be added to the ``user_variables.yml``:

.. code-block:: yaml

    swift_proxy_server_conf_overrides:
      DEFAULT:
        log_statsd_default_sample_rate: 10
        log_statsd_metric_prefix: "{{ inventory_hostname }}.swift"
        log_statsd_host: localhost
        log_statsd_port: 8125


Rewrite the swift proxy server configuration with :

.. code-block:: bash

     cd /opt/openstack-ansible/playbooks
     openstack-ansible os-swift-setup.yml --tags swift-config --forks 2
