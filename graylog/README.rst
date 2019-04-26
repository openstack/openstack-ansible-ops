Central Logging with Graylog2
=============================

Introduction
------------

This part of the ops repo is in charge of:

* Setting up Graylog2 into the ``graylog_hosts`` group
* Shipping all your hosts logs into Graylog2 using graylog native format (GELF)
* Configuring haproxy for Graylog2

Current limitations
-------------------

The upstream Graylog2 ansible role doesn't currently support deploying in a cluster
setup, and therefore the deploy needs to be restricted to one backend for now:
https://github.com/Graylog2/graylog-ansible-role/issues/89. It is all due to the
fact the authentication sessions have to be shared on a mongoDB cluster, and no
role is available to build the mongo cluster. Patches welcomed!

Fetching the roles
------------------

To install Graylog2 you need to make sure all the necessary roles are in your environment,
if you don't have them already.

You can re-use the bootstrap-ansible script with this ansible-role-requirement file
(see the OpenStack-Ansible reference documentation), or, simply run::

    ansible-galaxy install -r ansible-role-requirements.yml


Installing Graylog2 on graylog_hosts
------------------------------------

Add a file in /etc/openstack_deploy/user_graylog.yml, with the following content::

    graylog_password_secret: "" # The output of `pwgen -N 1 -s 96`
    graylog_root_username: "admin"
    graylog_root_password_sha2: "" # The output of `echo -n yourpassword | shasum -a 256`
    haproxy_extra_services:
      - service:
          haproxy_service_name: graylog
          haproxy_backend_nodes: "{{ [groups['graylog_hosts'][0]] | default([]) }}"
          haproxy_ssl: "{{ haproxy_ssl }}"
          haproxy_port: 9000
          haproxy_balance_type: http

See more Graylog2 deploy variables in
https://github.com/Graylog2/graylog-ansible-role/blob/e1159ec2712199f2da5768187cee84d1359bbd55/defaults/main.yml

If you want the ``graylog_hosts`` group to match the existing ``log_hosts`` group,
add the following in your ``/etc/openstack_deploy/inventory.ini``::

    [graylog_hosts:children]
    log_hosts

To deploy Graylog2, simply run the install playbook::

    openstack-ansible graylog2-install.yml

To point haproxy to your new Graylog2 instance, re-run the ``haproxy-install.yml`` playbook.

Note: If running Graylog2 on the same host as the load balancer, you'll hit an issue with an already
taken port. In that case, either don't configure haproxy, or configure it to run on an interface not yet
bound. For example, you can use the following line in your ``user_graylog.yml`` haproxy service section
to bind only on the external lb vip address::

    haproxy_bind: "{{ [external_lb_vip_address] }}"

Note: You can optionally add a series of headers in your haproxy to help on the web interface
redirection, if you have a specific network configuration.

     http-request set-header X-Graylog-Server-URL https://{{ external_lb_vip_address }}:9000/api

Configuration of Graylog2
-------------------------

Connect as the interface on your loadbalancer address, port 9000, with the user ``admin``, and the
previously defined password whose shasum was given into ``graylog_root_password_sha2``.

In the web interface, add the inputs you need.

If you want to configure your nodes with the provided playbook, you will need to
create a new GELF UDP input on at least one of your Graylog2 nodes (select ``global`` if you want to
listen on all the nodes).

For the exercise, we are defining the port to listen to as UDP 12201.

Sending logs to Graylog2
------------------------

Graylog2 can receive data with different protocols, but there is an efficient native format for it, GELF.

All of this is configured in a single playbook: ``graylog-forward-logs.yml``.

There are many packages to forward the journal into Graylog2, like the official `journal2gelf`_.
The ``graylog-ship-logs.yml`` playbook uses a fork of `journal2gelf` using `gelfclient`_.
It's lightweight and easy to install.

This script needs to know where to forward to, and depends on how you configured Graylog2 at the
previous step.

In the example above, the following variables need to be set in
``/etc/openstack_deploy/user_graylog.yml``::

    graylog_targets:
      - "{{ groups['graylog_hosts'][0] }}:12201"

If you are shipping journals directly from containers to the host, there is no need to run this playbook
on the full list of nodes. Instead, use the ansible ``--limit`` directive to restrict on which host
this playbook should run.

That's all folks!

.. _journal2gelf: https://github.com/systemd/journal2gelf
.. _gelfclient: https://github.com/nailgun/journal2gelf

