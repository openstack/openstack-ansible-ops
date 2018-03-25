install Elk stack with topbeat to gather metrics
#################################################
:tags: openstack, ansible


Changelog
---------
2018-03-06 Per Abildgaard Toft (per@minfejl.dk): Updated to version Elasticsearch,Logstash and Kibana 6.x. Changed Topebeat (deprecated) to metricbeat. Included haproxy endpoint configuration.


About this repository
---------------------

This set of playbooks will deploy elk cluster (Elasticsearch, Logstash, Kibana) with topbeat to gather metrics from hosts metrics to the ELK cluster.

Process
-------

Clone the elk-osa repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Copy the env.d file into place

.. code-block:: bash

    cd openstack-ansible-ops
    cp env.d/elk.yml /etc/openstack_deploy/env.d/

Copy the conf.d file into place

.. code-block:: bash

    cp conf.d/elk.yml /etc/openstack_deploy/conf.d/

In **elk.yml**, list your logging hosts under elastic-logstash_hosts to create the elasticsearch cluster in multiple containers and one logging host under kibana_hosts to create the kibana container

.. code-block:: bash

    vi /etc/openstack_deploy/conf.d/elk.yml

Create the containers

.. code-block:: bash

   cd /opt/openstack-ansible-playbooks
   openstack-ansible lxc-containers-create.yml -e 'container_group=elastic-logstash:kibana'

install master/data elasticsearch nodes on the elastic-logstash containers

.. code-block:: bash

    cd /opt/openstack-ansible-ops
    openstack-ansible installElastic.yml -e elk_hosts=elastic-logstash -e node_master=true -e node_data=true

Install an Elasticsearch client on the kibana container to serve as a loadbalancer for the Kibana backend server

.. code-block:: bash

    openstack-ansible installElastic.yml -e elk_hosts=kibana -e node_master=false -e node_data=false

Install Logstash on all the elastic containers

.. code-block:: bash

    openstack-ansible installLogstash.yml

Install Kibana, nginx reverse proxy and metricbeat on the kibana container

.. code-block:: bash

    openstack-ansible installKibana.yml

Conigure haproxy endpoints:

    Edit the /etc/openstack_deploy/user_variables.yml file and add fiel following lines:
.. code-block:: bash

  haproxy_extra_services:
   - service:
        haproxy_service_name: kibana
        haproxy_ssl: False
        haproxy_backend_nodes: "{{ groups['kibana'] | default([]) }}"
        haproxy_port: 81
        haproxy_balance_type: tcp

and then run the haproxy-install playbook
.. code-block:: bash
    cd /opt/openstack-ansible/playbooks/
     openstack-ansible haproxy-install.yml --tags=haproxy-service-config


install Metricbeat everywhere to start shipping metrics to our logstash instances

.. code-block:: bash

    openstack-ansible installMetricbeat.yml 

Trouble shooting:

If everything goes bad, you can clean up with the following command:

.. code-block:: bash
     openstack-ansible lxc-containers-destroy.yml --limit=elastic-logstash_all
