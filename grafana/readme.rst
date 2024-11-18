Install Grafana
###############
:tags: openstack, ansible

About this repository
---------------------

This set of playbooks will deploy Grafana. If this is being deployed as part of
an OpenStack all of the inventory needs will be provided for.

**These playbooks require Ansible 2.4+.**

Optional | configure haproxy endpoints
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Edit the `/etc/openstack_deploy/user_variables.yml` file and add fiel following
lines

.. code-block:: yaml

    haproxy_extra_services:
      - service:
          haproxy_service_name: grafana
          haproxy_ssl: "{{ haproxy_ssl }}"
          haproxy_backend_nodes: "{{ groups['grafana'] | default([]) }}"
          haproxy_port: 3000  # This is set using the "grafana_port" variable
          haproxy_balance_type: http

Deployment Process
------------------

Clone the grafana-osa repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Clone the grafana role

.. code-block:: bash

    cd /opt/openstack-ansible-ops/grafana
    ansible-galaxy install -r requirements.yml

Copy the env.d file into place

.. code-block:: bash

    cd /opt/openstack-ansible-ops/grafana
    cp env.d/grafana.yml /etc/openstack_deploy/env.d/

Copy the conf.d file into place

.. code-block:: bash

    cp conf.d/grafana.yml /etc/openstack_deploy/conf.d/

Create the containers

.. code-block:: bash

   cd /opt/openstack-ansible/playbooks
   openstack-ansible lxc-containers-create.yml -e 'container_group=grafana'

install grafana

.. code-block:: bash

    cd /opt/openstack-ansible-ops/grafana
    ANSIBLE_INJECT_FACT_VARS=True openstack-ansible installGrafana.yml
