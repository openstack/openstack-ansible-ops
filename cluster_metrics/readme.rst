Gather and visualize cluster wide metrics
#########################################
:date: 2016-09-01
:tags: openstack, ansible
:category: \*openstack, \*nix


About this repository
---------------------

This set of playbooks will deploy InfluxDB, Telegraf, Grafana and Kapacitor for the purpose of collecting
metrics on an OpenStack cluster.

Process
-------

Clone the OPS repo

.. code-block:: bash

    cd /opt
    git clone https://git.openstack.org/openstack/openstack-ansible-ops

Copy the env.d files into place

.. code-block:: bash

    cd openstack-ansible-ops/cluster_metrics
    cp etc/env.d/cluster_metrics.yml /etc/openstack_deploy/env.d/

Add the export to update the inventory file location

.. code-block:: bash

    export ANSIBLE_INVENTORY=/opt/openstack-ansible/playbooks/inventory/dynamic_inventory.py

If you are running the HA Proxy you should run the following playbook as well to enable the grafana port 8089

.. code-block:: bash

    openstack-ansible playbook-metrics-lb.yml

Create the containers

.. code-block:: bash

    openstack-ansible /opt/openstack-ansible/playbooks/lxc-containers-create.yml -e container_group=cluster-metrics

Install InfluxDB

.. code-block:: bash

    openstack-ansible playbook-influx-db.yml

Install Influx Telegraf

.. code-block:: bash

    openstack-ansible playbook-influx-telegraf.yml --forks 100

Install grafana

If you're proxy'ing grafana you will need to provide the full ``root_path`` when you run the playbook add the following ``-e grafana_root_url='https://cloud.something:8443/grafana/'``

.. code-block:: bash

    openstack-ansible playbook-grafana.yml -e galera_root_user=root -e galera_address='127.0.0.1'

Once that last playbook is completed you will have a functioning InfluxDB, Telegraf, and Grafana metric collection system active and collecting metrics. Grafana will need some setup, however functional dash boards have been provided in the ``grafana-dashboards`` directory.

Install Kapacitor

.. code-block:: bash

   openstack-ansible playbook-kapacitor.yml
