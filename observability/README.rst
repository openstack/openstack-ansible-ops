=============
Observability
=============

This document describes the Ansible Collection containing deployment and
configuration of observability tools and the which might be used together with
deployments managed by OpenStack-Ansible.

Installing the Collection
=========================

To install the collection, define it in your region deployment configuration file, located at `/etc/openstack_deploy/user-collection-requirements.yml`, as shown below:

.. code-block:: yaml

  collections:
    - name: osa_ops.observability
      type: git
      version: master
      source: https://opendev.org/openstack/openstack-ansible-ops#/observability

.. warning::

    Please, make sure to also add all content from the collection
    `requirements.yml <https://opendev.org/openstack/openstack-ansible-ops/src/branch/master/observability/requirements.yml>`_
    to your `user-collection-requirements.yml`.

Then, run ``./scripts/bootstrap-ansible.sh`` to install the collection.


Grafana
=======

For Grafana deployment we are leveraging `grafana.grafana <https://github.com/grafana/grafana-ansible-collection>`
collection.
Within this repository we maintain only a playbook and a set of variables
that will be used as defaults during deployment.


Deployment Process
^^^^^^^^^^^^^^^^^^

#. Copy the ``env.d`` content into ``/etc/openstack_deploy/env.d/grafana.yml``:

    .. literalinclude:: ../../observability/env.d/grafana.yml
        :language: yaml

#. Define hosts where Grafana should be deployed by placing definition to
   ``/etc/openstack_deploy/conf.d/grafana.yml`` or your
   ``openstack_user_config.yml``. Example:

   .. literalinclude:: ../../observability/conf.d/grafana.yml.example
       :language: yaml

#. Define the Grafana database and administrator passwords in
   ``/etc/openstack_deploy/user_secrets.yml`` before proceeding with
   the installation:

   .. code-block:: yaml

       grafana_db_password: <password>
       grafana_admin_password: <password>

#. Define overrides if needed. Following defaults are being used:

    .. literalinclude:: ../../observability/playbooks/group_vars/grafana_all/vars.yml
       :language: yaml

#. Create LXC containers for Grafana deployment

    .. code-block:: shell-session

        openstack-ansible openstack.osa.containers_lxc_create --limit grafana_all

#. Deploy Grafana

    .. code-block:: shell-session

        openstack-ansible openstack.osa_ops.grafana
