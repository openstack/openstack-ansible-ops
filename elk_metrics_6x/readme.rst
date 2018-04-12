Install ELK with beats to gather metrics
########################################
:tags: openstack, ansible

About this repository
---------------------

This set of playbooks will deploy elk cluster (Elasticsearch, Logstash, Kibana)
with topbeat to gather metrics from hosts metrics to the ELK cluster.

Process
-------

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

   cd /opt/openstack-ansible-playbooks
   openstack-ansible lxc-containers-create.yml -e 'container_group=elastic-logstash:kibana'

install master/data elasticsearch nodes on the elastic-logstash containers

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    openstack-ansible installElastic.yml

Install Logstash on all the elastic containers

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    openstack-ansible installLogstash.yml

Install Kibana, nginx reverse proxy and metricbeat on the kibana container

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    openstack-ansible installKibana.yml

Install Metricbeat everywhere to start shipping metrics to our logstash
instances

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    openstack-ansible installMetricbeat.yml

Optional | conigure haproxy endpoints

Edit the `/etc/openstack_deploy/user_variables.yml` file and add fiel following
lines

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

.. code-block:: bash

    cd /opt/openstack-ansible/playbooks/
    openstack-ansible haproxy-install.yml --tags=haproxy-service-config

Trouble shooting
^^^^^^^^^^^^^^^^

If everything goes bad, you can clean up with the following command

.. code-block:: bash

     openstack-ansible lxc-containers-destroy.yml --limit=kibana:elastic-logstash_all
