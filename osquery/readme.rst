Install OSQuery
###############
:tags: openstack, ansible

About this repository
---------------------

This set of playbooks will deploy osquery. If this is being deployed as part of
an OpenStack all of the inventory needs will be provided for.

There multiple ways to aggregate the data. At this point this repo does not provide
one of said methods.  It is currently intended to be utilized with the `elk_metrics_6x`.

It is the intention that at a later point to the ability to configure osquery to report
to a centralized place like (kolide/fleet)[https://github.com/kolide/fleet], (zentral)[https://github.com/zentralopensource/zentral],
etc.

**These playbooks require Ansible 2.4+.**

Deployment Process
------------------

Clone the osa ops repo

.. code-block:: bash

    cd /opt
    git clone https://github.com/openstack/openstack-ansible-ops

Clone the osquery role

.. code-block:: bash

    cd /opt
    git clone https://github.com/devx/ansible-osquery.git /etc/ansible/roles/osquery

install osquery

.. code-block:: bash

    cd /opt/openstack-ansible-ops/osquery
    openstack-ansible installOsquery.yml
