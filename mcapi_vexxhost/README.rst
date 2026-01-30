Vexxhost magnum-cluster-api driver
##################################

.. warning::

   The content for this repository has been moved and integrated with core
   OpenStack-Ansible content in 2026.1 (Gazpacho).
   Please refer to the `Magnum role documentation <https://docs.openstack.org/openstack-ansible-os_magnum/latest/>`_
   for configuration and design reference of the Magnum Cluster API driver.

   You can switch to prior releases (e.g. `2025.2 <https://docs.openstack.org/openstack-ansible-ops/2025.2/mcapi.html>`_)
   to check a code and documentation for this repository.

This documentation will guide you through the migration/upgrade process for
OpenStack Magnum deployment with Vexxhost CAPI driver, in case it has been
deployed prior to the 2026.1 (Gazpacho) release from the OPS repository.

Migrating from OPS repository to os_magnum integrated
-----------------------------------------------------

In 2026.1 (Gazpacho) release OpenStack-Ansible has performed a refactoring of
the Magnum service deployment, to ensure that Cluster API drivers are fully
supported out of the box and can be deployed as any other service, without
too many manual steps.

As most of the content has been promoted from the OPS repository to the
integrated OpenStack-Ansible deployment, a lot of configuration performed
prior to this change can be safely removed.
With that there are some extra configuration parameters, which should be
performed for the successful migration.

Please, adhere to the steps below in order to upgrade your deployment to
2026.1 (Gazpacho) release:

#. Remove ``vexxhost.kubernetes`` dependency from the
   `/etc/openstack_deploy/user-collection-requirements.yml` file

#. Remove ``docker-image-py`` and ``kubernetes`` dependencies from the
   `/etc/openstack_deploy/user-ansible-venv-requirements.txt` file

#. Rename ``cluster-api_hosts`` to ``cluster_api_hosts`` in
   `/etc/openstack_deploy/conf.d/k8s.yml`. While this change is optional,
   upgrade guide to 2026.1 includes recommendation to replace all dashes
   with underscores in conf.d files.

#. In case you have unchanged definition of ``haproxy_k8s_service`` and
   ``k8s_haproxy_services``, feel free to remove `/etc/openstack_deploy/group_vars/k8s_all/haproxy_service.yml`
   These variables are still effective, so it is safe to leave them defined
   as an override of the default value.

#. Please, carefully review overrides in the `/etc/openstack_deploy/group_vars/k8s_all/main.yml`
   It is safe to leave them "as is", as overrides of the default values.
   You can find default values defined in `OpenStack-Ansible's integrated repository <https://opendev.org/openstack/openstack-ansible/src/branch/master/inventory/group_vars/k8s_all/defaults.yml>`_

#. In most cases, overrides applied in `/etc/openstack_deploy/group_vars/magnum_all/main.yml`
   can be removed, with special attention to following values:

   * ``openstack_ca_file`` and ``ca_file`` - these values are now controlled
     with a variable ``magnum_capi_ca_file``, which by default points to
     `/etc/ssl/certs/ca-certificates.crt`.
   * ``kubernetes_allowed_network_drivers`` and
     ``kubernetes_default_network_driver`` are now controlled with a variable
     ``magnum_capi_network_driver_default`` which defaults to ``calico``.
   * ``magnum_magnum_cluster_api_git_install_branch`` - has been replaced
     with the ``magnum_capi_vexxhost_git_install_branch`` and
     defaults to ``v0.36.6`` for 2026.1 release.
   * ``magnum_magnum_cluster_api_git_repo`` has been replaced with a
     variable ``magnum_capi_vexxhost_git_repo``.

#. You *need* to add a variable ``magnum_k8s_driver: vexxhost`` to
   `/etc/openstack_deploy/group_vars/magnum_all/main.yml`

#. Playbook ``osa_ops.mcapi_vexxhost.k8s_install`` has been replaced with a
   ``openstack.osa.k8s``

#. In case you have used ``magnum-cluster-api-proxy``:

   * Variable ``mcapi_vexxhost_proxy_hosts`` has been renamed to ``magnum_capi_vexxhost_proxy_hosts``
   * Playbook ``osa_ops.mcapi_vexxhost.mcapi_proxy`` has been replaced with ``openstack.osa.magnum_capi_proxy``
