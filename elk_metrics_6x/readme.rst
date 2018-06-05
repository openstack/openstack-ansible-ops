Install ELK with beats to gather metrics
########################################
:tags: openstack, ansible


About this repository
---------------------

This set of playbooks will deploy elk cluster (Elasticsearch, Logstash, Kibana)
with topbeat to gather metrics from hosts metrics to the ELK cluster.

**These playbooks require Ansible 2.5+.**


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


Optional | add OSProfiler to an OpenStack-Ansible deployment
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

To initalize the `OSProfiler` module within openstack the following overrides
can be applied to the to a user variables file. The hmac key needs to be defined
consistently throughout the environment.

Full example to initialize the `OSProfiler` modules throughout an
OpenStack-Ansible deployment.

.. code-block:: yaml

    profiler_overrides: &os_profiler
      profiler:
        enabled: true
        trace_sqlalchemy: true
        hmac_keys: "UNIQUE_HMACKEY"  # This needs to be set consistently throughout the deployment
        connection_string: "elasticsearch://{{ internal_lb_vip_address }}:9201"
        es_doc_type: "notification"
        es_scroll_time: "2m"
        es_scroll_size: "10000"
        filter_error_trace: "false"

    aodh_aodh_conf_overrides: *os_profiler
    barbican_config_overrides: *os_profiler
    ceilometer_ceilometer_conf_overrides: *os_profiler
    cinder_cinder_conf_overrides: *os_profiler
    designate_designate_conf_overrides: *os_profiler
    glance_glance_api_conf_overrides: *os_profiler
    gnocchi_conf_overrides: *os_profiler
    heat_heat_conf_overrides: *os_profiler
    horizon_config_overrides: *os_profiler
    ironic_ironic_conf_overrides: *os_profiler
    keystone_keystone_conf_overrides: *os_profiler
    magnum_config_overrides: *os_profiler
    neutron_neutron_conf_overrides: *os_profiler
    nova_nova_conf_overrides: *os_profiler
    octavia_octavia_conf_overrides: *os_profiler
    rally_config_overrides: *os_profiler
    sahara_conf_overrides: *os_profiler
    swift_swift_conf_overrides: *os_profiler
    tacker_tacker_conf_overrides: *os_profiler
    trove_config_overrides: *os_profiler


If a deployer wishes to use multiple keys they can do so by with comma seperated
list.

.. code-block:: yaml

    profiler_overrides: &os_profiler
      profiler:
        hmac_keys: "key1,key2"


To add the `OSProfiler` section to an exist set of overrides, the `yaml` section
can be added or dynamcally appended to a given hash using `yaml` tags.

.. code-block:: yaml

    profiler_overrides: &os_profiler
      profiler:
        enabled: true
        hmac_keys: "UNIQUE_HMACKEY"  # This needs to be set consistently throughout the deployment
        connection_string: "elasticsearch://{{ internal_lb_vip_address }}:9201"
        es_doc_type: "notification"
        es_scroll_time: "2m"
        es_scroll_size: "10000"
        filter_error_trace: "false"

    # Example to merge the os_profiler tag to into an existing override hash
    nova_nova_conf_overrides:
      section1_override:
        key: "value"
      <<: *os_profiler


While the `osprofiler` and `elasticsearch` libraries should be installed
within all virtual environments by default, it's possible they're missing
within a given deployment. To install these dependencies throughout the
cluster without having to invoke a *repo-build* run the following *adhoc*
Ansible command can by used.

.. code-block:: bash

    ansible -m shell -a 'find /openstack/venvs/* -maxdepth 0 -type d -exec {}/bin/pip install osprofiler elasticsearch \;' all


Once the overides are inplace the **openstack-ansible** playbooks will need to
be rerun. To simply inject these options into the system a deployer will be able
to use the `*-config` tags that are apart of all `os_*` roles. The following
example will run the **config** tag on **ALL** openstack playbooks.

.. code-block:: bash

    openstack-ansible setup-openstack.yml --tags "$(cat setup-openstack.yml | grep -wo 'os-.*' | awk -F'-' '{print $2 "-config"}' | tr '\n' ',')"


Once the `OSProfiler` module has been initialized tasks can be profiled on
demand by using the `--profile` or `--os-profile` switch in the various
openstack clients along with one of the given hmac keys defined.

Legacy profile example command.

.. code-block:: bash

    glance --profile key1 image-list


Modern profile example command, requires `python-openstackclient >= 3.4.1` and
the `osprofiler` library.

.. code-block:: bash

    openstack --os-profile key2 image list


If the client library is not installed in the same path as the
`python-openstackclient` client, run the following command to install the
required library.

.. code-block:: bash

    pip install osprofiler


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
   openstack-ansible lxc-containers-create.yml -e 'container_group=elastic-logstash:kibana:apm-server'


Deploying | Installing with embedded Ansible
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

If this is being executed on a system that already has Ansible installed but is
incompatible with these playbooks the script `bootstrap-embedded-ansible.sh` can
be sourced to grab an embedded version of Ansible prior to executing the
playbooks.

.. code-block:: bash

    source bootstrap-embedded-ansible.sh


Deploying | Manually resolving the dependencies
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

This playbook has external role dependencies. If Ansible is not installed with
the `bootstrap-ansible.sh` script these dependencies can be resolved with the
``ansible-galaxy`` command and the ``ansible-role-requirements.yml`` file.

* Example galaxy execution

.. code-block:: bash

    ansible-galaxy install -r ansible-role-requirements.yml


Once the dependencies are set make sure to set the action plugin path to the
location of the config_template action directory. This can be done using the
environment variable `ANSIBLE_ACTION_PLUGINS` or through the use of an
`ansible.cfg` file.


Deploying | The environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Install master/data elasticsearch nodes on the elastic-logstash containers,
deploy logstash, deploy kibana, and then deploy all of the service beats.

.. code-block:: bash

    cd /opt/openstack-ansible-ops/elk_metrics_6x
    ansible-playbook site.yml $USER_VARS


* The `openstack-ansible` command can be used if the version of ansible on the
  system is greater than **2.5**.


The individual playbooks found within this repository can be independently run
at anytime.


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

Example command using the embedded Ansible from within the grafana directory.

.. code-block:: bash

    ansible-playbook ${USER_VARS} installGrafana.yml \
                                  -e @../elk_metrics_6x/vars/variables.yml \
                                  -e galera_root_user=root \
                                  -e 'galera_address={{ internal_lb_vip_address }}'


Trouble shooting
----------------

If everything goes bad, you can clean up with the following command

.. code-block:: bash

     openstack-ansible /opt/openstack-ansible-ops/elk_metrics_6x/site.yml -e "elk_package_state=absent" --tags package_install
     openstack-ansible /opt/openstack-ansible/playbooks/lxc-containers-destroy.yml --limit=kibana:elastic-logstash_all
