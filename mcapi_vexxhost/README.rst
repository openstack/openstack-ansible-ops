Install vexxhost magnum-cluster-api driver
##########################################

About this repository
---------------------

This repository includes playbooks and roles to deploy the Vexxhost
magnum-cluster-api driver for the OpenStack Magnum service.

The playbooks create a complete deployment including the control plane
k8s cluster which should result in a ready-to-go experience for operators.

The following architectural features are present:

* The control plane k8s cluster is an integral part of the openstack-ansible
  deployment, and forms part of the foundational components alongside mariadb
  and rabbitmq.
* The control plane k8s cluster is deployed on the infra hosts and integrated
  with the haproxy loadbalancer and OpenStack internal API endpoint, and not
  exposed outside of the deployment
* SSL is supported between all components and configuration is
  possible to support different certificate authorities on the internal
  and external loadbalancer endpoints.
* Control plane traffic can stay entirely within the management network
  if required
* The magnum-cluster-api-proxy service is deployed to allow communication
  between the control plane and workload clusters when a floating IP is not
  attached to the workload cluster.

* It is possible to do a completely offline install for airgapped environments

The magnum-cluster-api driver for magnum can be found here https://github.com/vexxhost/magnum-cluster-api

Documentation for the Vexxhost magnum-cluster-api driver is here https://vexxhost.github.io/magnum-cluster-api/

The ansible collection used to deploy the controlplane k8s cluster is here https://github.com/vexxhost/ansible-collection-kubernetes

The ansible collection used to deploy the container runtime for the controlplane k8s cluster is here https://github.com/vexxhost/ansible-collection-containers

**These playbooks require Openstack-Ansible Caracal or later.**

Highlevel overview of the Magnum infrastructure these playbooks will
build and operate against.

.. image:: assets/mcapi-architecture.png
    :scale: 100 %
    :alt: OSA Magnum Cluster API Architecture
    :align: center

Pre-requisites
--------------

* An existing openstack-ansible deployment
* Control plane using LXC containers, bare metal deployment is not tested
* Core openstack services plus Octavia

OpenStack-Ansible Integration
-----------------------------

.. note:
   The example configuration files shown below are suitable for use with an
   openstack-ansible All-In-One (AIO) build and can be found at
   openstack-ansible-ops/mcapi_vexxhost/playbooks/files/openstack_deploy/

The playbooks are distributed as an ansible collection, and integrate with
Openstack-Ansible by adding the collection to the deployment host by
adding the following to  `/etc/openstack_deploy/user-collection-requirements.yml`
under the collections key.

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/user-collection-requirements.yml
   :language: yaml

The collections can then be installed with the following command:

  .. code-block:: bash

      cd /opt/openstack-ansible
      openstack-ansible scripts/get-ansible-collection-requirements.yml

The modules in the kubernetes collection require an additional python module
to be present in the ansible-runtime python virtual environment. Specify this
in /etc/openstack_deploy/user-ansible-venv-requirements.txt

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/user-ansible-venv-requirements.txt
   :language: yaml

OpenStack-Ansible configuration for magnum-cluster-api driver
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Specify the deployment of the control plane k8s cluster in
`/etc/openstack_deploy/env.d/k8s.yml`

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/env.d/k8s.yml
   :language: yaml

Define the physical hosts that will host the controlplane k8s
cluster in /etc/openstack_deploy/conf.d/k8s.yml. This example is
for an all-in-one deployment and should be adjusted to match a real
deployment with multiple hosts if high availability is required.

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/conf.d/k8s.yml
   :language: yaml

Integrate the control plane k8s cluster with the haproxy loadbalancer
in `/etc/openstack_deploy/group_vars/k8s_all/haproxy_service.yml`

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/group_vars/k8s_all/haproxy_service.yml
   :language: yaml

Configure the LXC container that will host the control plane k8s cluster to
be suitable for running nested containers in `/etc/openstack_deploy/group_vars/k8s_all/main.yml`

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/group_vars/k8s_all/main.yml
   :language: yaml

Set up config-overrides for the magnum service in `/etc/openstack_deploy/user_variables_magnum.yml`.
Adjust the images and flavors here as necessary, these are just for demonstration. Upload as many
images as you need for the different workload cluster kubernetes versions.

Attention must be given to the SSL configuration. Users and workload clusters will
interact with the external endpoint and must trust the SSL certificate. The magnum
service and cluster-api can be configured to interact with either the external or
internal endpoint and must trust the SSL certificiate. Depending on the environment,
these may be derived from different certificate authorities.

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/user_variables_z_magnum.yml
   :language: yaml

Set up config-overrides for the control plane k8s cluster in /etc/openstack_deploy/user_variables_k8s.yml`
These variables integrate the control plane k8s deployment with the rest of the
openstack-ansible deployment.

.. literalinclude:: ../../mcapi_vexxhost/playbooks/files/openstack_deploy/user_variables_k8s.yml
   :language: yaml

Run the deployment
------------------

For a new deployment
^^^^^^^^^^^^^^^^^^^^

Run the OSA playbooks/setup.yml playbooks as usual, following the normal
deployment guide.

Run the magnum-cluster-api deployment

  .. code-block:: bash

     openstack-ansible osa_ops.mcapi_vexxhost.k8s_install

For an existing deployment
^^^^^^^^^^^^^^^^^^^^^^^^^^

Ensure that the python modules required for ansible are present:

  .. code-block:: bash

     ./scripts/bootstrap-ansible.sh

Alternatively, without re-running the bootstrap script:

  .. code-block:: bash

     /opt/ansible-runtime/bin/pip install docker-image-py

Add the magnum-cluser-api driver to the magnum service

  .. code-block:: bash

     openstack-ansible playbooks/os-magnum-install.yml

Create the k8s control plane containers

  .. code-block:: bash

     openstack-ansible playbooks/lxc-containers-create.yml --limit k8s_all

Run the magnum-cluster-api deployment

  .. code-block:: bash

     openstack-ansible osa_ops.mcapi_vexxhost.k8s_install

Optionally run a functional test of magnum-cluster-api
------------------------------------------------------

This can be done quickly using the following playbook

  .. code-block:: bash

     openstack-ansible osa_ops.mcapi_vexxhost.functional_test

This playbook will create a neutron public network, download a prebuilt
k8s glance image, create a nova flavor and a magnum cluster template.

It will then deploy the workload k8s cluster using magnum, and
run a sonobouy "quick mode" test of the workload cluster.

This playbook is intended to be used on an openstack-ansible
all-in-one deployment.

Use Magnum to create a workload cluster
---------------------------------------

Upload Images

Create a cluster template

Create a workload cluster

Optional Components
-------------------

Deploy the workload clusters with a local registry
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TODO - describe how to do this

Deploy the control plane cluster from a local registry
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TODO - describe how to do this

Use of magnum-cluster-api-proxy
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

TODO - describe what this is for

Troubleshooting
---------------

Local testing
-------------

An OpenStack-Ansible all-in-one configured with Magnum and Octavia is
capable of running a functioning magnum-cluster-api deployment.

Sufficient memory should be available beyond the minimum 8G usually required
for an all-in-one. A multinode workload cluster may require nova to boot several
Ubuntu images in addition to an Octavia loadbalancer instance. 64G would
be an appropriate amount of system RAM.

There also must be sufficient disk space in `/var/lib/nova/instances` to
support the required number of instances - the normal minimum of 60G
required for an all-in-one deployment will be insufficient, 500G would
be plenty.

