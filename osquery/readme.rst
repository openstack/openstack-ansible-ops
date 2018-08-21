Install OSQuery and Kolide fleet
################################
:tags: openstack, ansible

Table of Contents
=================

      * [About this repository](#about-this-repository)
      * [OpenStack-Ansible Integration](#openstack-ansible-integration)
      * [TODO](#todo)


About this repository
---------------------

This set of playbooks will deploy osquery. If this is being deployed as part of
an OpenStack all of the inventory needs will be provided for.


**These playbooks require Ansible 2.4+.**

Highlevel overview of Osquery & Kolide Fleet  infrastructure these playbooks will
build and operate against.

.. image:: assets/overview-osquery.png
    :scale: 50 %
    :alt: Osquery & Kolide Fleet Architecture Diagram
    :align: center

OpenStack-Ansible Integration
-----------------------------

These playbooks can be used as standalone inventory or as an integrated part of
an OpenStack-Ansible deployment. For a simple example of standalone inventory,
see ``inventory.example.yml``.

Setup | system configuration
^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Clone the osquery-osa repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Copy the env.d file into place

.. code-block:: bash

    cd /opt/openstack-ansible-ops/osquery
    cp env.d/fleet.yml /etc/openstack_deploy/env.d/

Copy the conf.d file into place

.. code-block:: bash

    cp conf.d/fleet.yml /etc/openstack_deploy/conf.d/

In **fleet.yml**, list your logging hosts under fleet-logstash_hosts to create
the kolide fleet cluster in multiple containers and one logging host under
`fleet_hosts` to create the fleet container

.. code-block:: bash

    vi /etc/openstack_deploy/conf.d/fleet.yml

Create the containers

.. code-block:: bash

   cd /opt/openstack-ansible/playbooks
   openstack-ansible lxc-containers-create.yml --limit fleet_all


Update the `/etc/hosts` file *(optional)*

.. code-block:: bash

   cd /opt/openstack-ansible/playbooks
   openstack-ansible openstack-hosts-setup.yml



Create an haproxy entry for kolide-fleet service 8443

.. code-block:: bash

    cd /opt/openstack-ansible-ops/osquery
    cat haproxy.example  >> /etc/openstack_deploy/user_variables.yml

    cd /opt/openstack-ansible/playbooks/
    openstack-ansible haproxy-install.yml --tags=haproxy-service-config


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


In the even that some of the modules are alread installed execute the following

.. code-block:: bash

    ansible-galaxy install -r ansible-role-requirements.yml --ignore-errors


Once the dependencies are set make sure to set the action plugin path to the
location of the config_template action directory. This can be done using the
environment variable `ANSIBLE_ACTION_PLUGINS` or through the use of an
`ansible.cfg` file.


Deploying | The environment
^^^^^^^^^^^^^^^^^^^^^^^^^^^

Create some basic passwords keys that are needed by fleet
.. code-block:: bashG

    echo "kolide_fleet_jwt_key: $(openssl rand -base64 32)" > /etc/openstack_deploy/fleet_user_vars.yml
    echo "mariadb_root_password: $(openssl rand -base64 16)" >> /etc/openstack_deploy/fleet_user_vars.yml


Install master/data Fleet nodes on the elastic-logstash containers,
deploy logstash, deploy Kibana, and then deploy all of the service beats.

.. code-block:: bashG

    cd /opt/openstack-ansible-ops/osquery
    ansible-playbook site.yml -e@/etc/openstack_deploy/fleet_user_vars.yml


* The `openstack-ansible` command can be used if the version of ansible on the
  system is greater than **2.5**. This will automatically pick up the necessary
  group_vars for hosts in an OSA deployment.

* If required add ``-e@/opt/openstack-ansible/inventory/group_vars/all/all.yml``
  to import sufficient OSA group variables to define the OpenStack release.
  Journalbeat will then deploy onto all hosts/containers for releases prior to
  Rocky, and hosts only for Rocky onwards. If the variable ``openstack_release``
  is undefined the default behaviour is to deploy Journalbeat to hosts only.

* Alternatively if using the embedded ansible, create a symlink to include all
  of the OSA group_vars. These are not available by default with the embedded
  ansible and can be symlinked into the ops repo.

.. code-block:: bash

    ln -s /opt/openstack-ansible/inventory/group_vars /opt/openstack-ansible-ops/osquery/group_vars


The individual playbooks found within this repository can be independently run
at anytime.

Architecture | Data flow
^^^^^^^^^^^^^^^^^^^^^^^^

This diagram outlines the data flow from within an Elastic-Stack deployment.

.. image:: assets/architecture-osquery.png
    :scale: 50 %
    :alt: Kolide & Osquery Data Flow Diagram
    :align: center

TODO
----
The following is a list of open items.
 - [x] Test Redhat familly Operating Systems
 - [x] missing mariadb cluster (should all work needs additional vars)
 - [ ] use haproxy instead of the kolide fleet server ip
 - [ ] add/update tags
 - [ ] convert to roles
 - [ ] add testing
