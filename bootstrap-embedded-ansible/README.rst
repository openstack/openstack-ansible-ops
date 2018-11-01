Create an embedded Ansible runtime
##################################
:tags: embedded, ansible


About this repository
---------------------

The embedded ansible script will create an ansible runtime within the users home folder.
This ansible runtime will be within a virtual envrionment and have all of the plugins
required to run ansible standalone or in an OpenStack-Ansible compatible envrionment.


Usage
^^^^^

.. code-block:: bash

   source bootstrap-embedded-ansible.sh


With the script sourced, the ansible environment will create a virtual environment at
`${HOME}/ansible_venv` if it does not already exist.

To leave the embedded ansible enviornment run the function `deactivate`.
