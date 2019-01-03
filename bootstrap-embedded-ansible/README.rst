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

To leave the embedded ansible environment run the function `deactivate`.


Options
^^^^^^^

All options are passed in using environment variables.

ANSIBLE_VERSION:
  Allows for the Ansible XXX to be overridden. When set the full ansible version is required.

ANSIBLE_EMBED_HOME:
  Allows for the Ansible XXX to be overridden. When set the full path is required.

ANSIBLE_ROLE_REQUIREMENTS:
  Allows for the Ansible XXX to be overridden. When set the full path to the role requirements file is required.

ANSIBLE_PYTHON_REQUIREMENTS:
  Allows for the Ansible XXX to be overridden. When set the full path to the python requirements file is required.
