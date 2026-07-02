=============
Observability
=============

This document describes the Ansible Collection containing deployment and
configuration of observability tools and the which might be used together with
deployments managed by OpenStack-Ansible.

Installing the Collection
-------------------------

To install the collection, define it in your region deployment configuration file, located at `/etc/openstack_deploy/user-collection-requirements.yml`, as shown below:

.. code-block:: yaml

  - name: osa_ops.observability
    type: git
    version: master
    source: https://opendev.org/openstack/openstack-ansible-ops#/observability

Then, run `./scripts/bootstrap-ansible.sh` to install the collection.
