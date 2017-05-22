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
* The ``rolling_test.py`` script

The ``rolling_restart.py`` script will stop containers from a specified group
in a rolling fashion - node 1 will stop, then start, then node 2, then
node 3 and so on. This script runs from the *deployment host*.

The ``tests`` directory contains scripts to generate traffic against the
target services.
system that will be restarted by ``rolling_restart.py`` in order to
measure the effects. These scripts run from a *utility container*.

The ``rolling_test.py`` script contains tests to generate traffic against the
target services. These vary per service, but attempt to apply usage to a
system that will be restarted by ``rolling_restart.py`` in order to
measure the effects. This script runs from a *utility container*.

Usage
-----

#. Start your test from a utility container. ``./rolling_test.py keystone``
   runs the Keystone test. ``./rolling_test.py list`` will list tests and
   their descriptions
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
physical host to target is derived from the current inventory.

``rolling_restart.py`` must currently be run from the ``playbooks``
directory. This will be fixed later.

You must source ``openrc`` before running ``rolling_test.py``.


Creating New Tests
------------------

Tests should subclass from the ``ServiceTest`` class in the same file
and implement the following properties and methods:

#. ``run`` - The actual test to run should be placed in this method. Timings
    will be gathered based on when this function starts and stops.

#. ``pre_test`` - Any pre-test setup that needs to happen, like creating a
    file for Glance, Cinder, or Swift upload.

#. ``post_test`` - Any post-test teardown that might be needed.

#. ``service_name`` - The primary service that is being tested.

#. ``description`` - Brief description of what the test does.

Finally, add the test to the ``available_tests`` dictionary with the
invocation name as the key and the class as the value.


Why the name?
-------------

It sets 'em up and knocks em down.
