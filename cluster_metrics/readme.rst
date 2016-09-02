Gather and visualize cluster wide metrics
#########################################
:date: 2016-09-01
:tags: openstack, ansible
:category: \*openstack, \*nix


About this repository
---------------------

This set of playbooks will deploy InfluxDB, Telegraf, and Grafana for the purpose of collecting metrics on an OpenStack cluster.

Process
-------

Clone the OPS repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Copy the env.d files into place

.. code-block:: bash

    cd openstack-ansible-ops/cluster_metrics
    cp etc/env.d/cluster_metrics.yml /etc/openstack_deploy/env.d/

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
