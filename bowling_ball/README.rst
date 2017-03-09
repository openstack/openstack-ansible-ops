Bowling Ball - OpenStack-Ansible Rolling Downtime Simulator
###########################################################
:date: 2017-03-09
:tags: rackspace, openstack, ansible
:category: \*openstack, \*nix

About
-----

This project aims to test for issues with rolling downtime on
OpenStack-Ansible deployments. It's comprised of two main components:

* The ``rolling_restart.py`` script
* The ``tests`` directory

The ``rolling_restart.py`` script will stop containers from a specified group
in a rolling fashion - node 1 will stop, then start, then node 2, then
node 3 and so on. This script runs from the *deployment host*.

The ``tests`` directory contains scripts to generate traffic against the
target services. These vary per service, but attempt to apply usage to a
system that will be restarted by ``rolling_restart.py`` in order to
measure the effects. These scripts run from a *utility container*.


Usage
-----

#. Start your test script from the utility container. ``keystone.py``
   will request a session and a list of projects on an infinite loop, for
   example.
#. From the deployment node, run ``rolling_restart.py`` in the playbooks
   directory (necessary to find the inventory script). Specify the service
   you're targeting with the ``-s`` parameter.

    ``rolling_restart.py -s keystone_container``

    You can specify a wait time in seconds between stopping and starting
    individual nodes.

    ``rolling_restart.py -s keystone_container -w 60``


Assumptions
-----------

These tools are currently coupled to OSA, and they assume paths to files
as specified by the ``multi-node-aio`` scripts.

Container stopping and starting is done with an ansible command, and the
physical host to target is derivced from the current inventory.

``rolling_restart.py`` must currently be run from the ``playbooks``
directory. This will be fixed later.

You must source ``openrc`` before running ``keystone.py``.


Why the name?
-------------

It sets 'em up and knocks em down.
