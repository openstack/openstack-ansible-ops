========================
Team and repository tags
========================

.. image:: http://governance.openstack.org/badges/openstack-ansible-ops.svg
    :target: http://governance.openstack.org/reference/tags/index.html

.. Change things from this point on

OpenStack-Ansible Operator Tooling
==================================

This repository is a collecting point for various scripts and tools which
OpenStack-Ansible Developers and Operators have found to be useful and
want to share and collaboratively improve.

The contents of this repository are not strictly quality managed and are
only tested by hand by the contributors and consumers. Anyone using the
tooling is advised to very clearly understand what it is doing before using
it on a production environment.

Galaxy roles
~~~~~~~~~~~~

`OpenStack Ansible backup <https://galaxy.ansible.com/winggundamth/openstack-ansible-backup/>`_
-----------------------------------------------------------------------------------------------

 This role will perform backups for OpenStack-Ansible deployments and it needs
 to run on the deploy node. It will backup data on container and then
 synchronize backup files to the deploy node.
