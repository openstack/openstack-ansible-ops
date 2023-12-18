Install Prometheus
##################
:tags: openstack, ansible

About this repository
---------------------

This set of playbooks will deploy Prometheus. If this is being deployed as part of
an OpenStack all of the inventory needs will be provided for.

**These playbooks require Ansible 2.4+.**

Deployment Process
------------------

Clone the repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Downloading role dependencies

.. code-block:: bash

    cd /opt/openstack-ansible-ops/prometheus
    ansible-galaxy install -r requirements.yml


Install node_exporter

.. code-block:: bash

    cd /opt/openstack-ansible-ops/prometheus
    openstack-ansible installNodeExporter.yml


If you want to deploy the mysqld_exporter, you need to create the Galera user for it first

.. code-block:: yaml

    galera_additional_users:
      - name: "exporter"
        host: '%'
        password: "{{ prometheus_mysqld_exporter_galera_password }}"
        priv: '*.*:PROCESS,REPLICATION CLIENT,SELECT,SLAVE MONITOR'
        resource_limits:
          MAX_USER_CONNECTIONS: 3
        check_hostname: false
        state: present


Then install the mysqld_exporter

.. code-block:: bash

    cd /opt/openstack-ansible-ops/prometheus
    openstack-ansible installMysqldExporter.yml
