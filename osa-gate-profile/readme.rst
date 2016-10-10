Generate metrics from openstack-ansible gate check console logs
###############################################################
:date: 2016-10-10
:tags: openstack, ansible
:category: \*openstack, \*nix


About this repository
---------------------

These scripts will query logstash.openstack.org to find a set of OSA gate check
console logs, download them, and perform task timing analytics.

- step1: fetchlogs.php
- step2: parselogs.php
- step3: generatereports.php

Example run
-----------

.. code-block:: bash

    mkdir dump
    php fetchlogs.php
    php parselogs.php > intermediary.json
    php generatereports.php intermediary.json
    rm -rf intermediary.json
