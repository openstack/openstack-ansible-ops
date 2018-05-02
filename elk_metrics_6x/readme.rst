Install ELK with beats to gather metrics
########################################
:tags: openstack, ansible


About this repository
---------------------

This set of playbooks will deploy elk cluster (Elasticsearch, Logstash, Kibana)
with topbeat to gather metrics from hosts metrics to the ELK cluster.

**These playbooks require Ansible 2.5+.**

Before running these playbooks the ``systemd_service`` role is required and is
used in community roles. If these playbooks are being run in an
OpenStack-Ansible installation the required role will be resolved for you. If
the Installation is outside of OpenStack-Ansible, clone the role or add it to an
ansible role requirements file.

.. code-block:: bash

    git clone https://github.com/openstack/ansible-role-systemd_service /etc/ansible/roles/systemd_service


OpenStack-Ansible Integration
-----------------------------

These playbooks can be used as standalone inventory or as an integrated part of
an OpenStack-Ansible deployment. For a simple example of standalone inventory,
see ``inventory.example.yml``.


Optional | Load balancer VIP address
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

In order to use multi-node elasticsearch a loadbalancer is required. Haproxy can
provide the load balancer functionality needed. The option
`internal_lb_vip_address` is used as the endpoint (virtual IP address) services
like Kibana will use when connecting to elasticsearch. If this option is
omitted, the first node in the elasticsearch cluster will be used.


Optional | configure haproxy endpoints
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Edit the `/etc/openstack_deploy/user_variables.yml` file and add the following
lines.

.. code-block:: yaml

    haproxy_extra_services:
     - service:
          haproxy_service_name: kibana
          haproxy_ssl: False
          haproxy_backend_nodes: "{{ groups['kibana'] | default([]) }}"
          haproxy_port: 81  # This is set using the "kibana_nginx_port" variable
          haproxy_balance_type: tcp
      - service:
          haproxy_service_name: elastic-logstash
          haproxy_ssl: False
          haproxy_backend_nodes: "{{ groups['elastic-logstash'] | default([]) }}"
          haproxy_port: 5044  # This is set using the "logstash_beat_input_port" variable
          haproxy_balance_type: tcp
      - service:
          haproxy_service_name: elastic-logstash
          haproxy_ssl: False
          haproxy_backend_nodes: "{{ groups['elastic-logstash'] | default([]) }}"
          haproxy_port: 9201  # This is set using the "elastic_hap_port" variable
          haproxy_check_port: 9200  # This is set using the "elastic_port" variable
          haproxy_backend_port: 9200  # This is set using the "elastic_port" variable
          haproxy_balance_type: tcp


Optional | run the haproxy-install playbook
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

.. code-block:: bash

    cd /opt/openstack-ansible/playbooks/
    openstack-ansible haproxy-install.yml --tags=haproxy-service-config


Setup | system configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Clone the elk-osa repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Copy the env.d file into place

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    cp env.d/elk.yml /etc/openstack_deploy/env.d/

Copy the conf.d file into place

.. code-block:: bash

    cp conf.d/elk.yml /etc/openstack_deploy/conf.d/

In **elk.yml**, list your logging hosts under elastic-logstash_hosts to create
the elasticsearch cluster in multiple containers and one logging host under
kibana_hosts to create the kibana container

.. code-block:: bash

    vi /etc/openstack_deploy/conf.d/elk.yml

Create the containers

.. code-block:: bash

   cd /opt/openstack-ansible/playbooks
   openstack-ansible lxc-containers-create.yml -e 'container_group=elastic-logstash:kibana'


Deployment | legacy environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If these playbooks are to be run in an environment that does not have access to
modern Ansible source the script ``bootstrap-embeded-ansible.sh`` before running
the playbooks. This script will install Ansible **2.5.2** in a virtual
environment within ``/opt``. This will provide for everything needed to run
these playbooks in an OpenStack-Ansible cloud without having to upgrade the
Ansible version from within the legacy environment. When it comes time to
execute these playbooks substite the ``openstack-ansible`` command with the
full path to ``ansible-playbook`` within the embeded ansible virtual
environment making sure to include the available user provided variables.

Example commands to deploy all of these playbooks using the embeded ansible.

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    source bootstrap-embeded-ansible.sh
    /opt/ansible25/bin/ansible-playbook ${ANSIBLE_USER_VARS} site.yml


Deploying | modern environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Install master/data elasticsearch nodes on the elastic-logstash containers,
deploy logstash, deploy kibana, and then deploy all of the service beats.

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    openstack-ansible site.yml


Optional | add Grafana visualizations
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

See the grafana directory for more information on how to deploy grafana. Once
When deploying grafana, source the variable file from ELK in order to
automatically connect grafana to the Elasticsearch datastore and import
dashboards. Including the variable file is as simple as adding
``-e @../elk_metrics_6x/vars/variables.yml`` to the grafana playbook
run.

Included dashboards.

* https://grafana.com/dashboards/5569
* https://grafana.com/dashboards/5566


Trouble shooting
----------------

If everything goes bad, you can clean up with the following command

.. code-block:: bash

     openstack-ansible /opt/openstack-ansible-ops/elk_metrics_6x/site.yml -e "elk_package_state=absent" --tags package_install
     openstack-ansible /opt/openstack-ansible/playbooks/lxc-containers-destroy.yml --limit=kibana:elastic-logstash_all
