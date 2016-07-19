==============================================
OpenStack-Ansible Diff Generator Documentation
==============================================

Getting a list of commits between two OpenStack-Ansible tags is fairly easy
with ``git diff``, but it can be difficult to review other changes between
those tags, such as:

* Changes to OpenStack projects that OpenStack-Ansible downloads and compiles
  into python wheels on the repo servers
* Changes to independent OpenStack-Ansible roles (Mitaka and later releases)

The ``osa-differ.py`` script retrieves all of these changes and displays them
in an easy-to-read RST-formatted document.

The script queries GitHub's API and downloads some raw code to determine the
changes in each repository. This allows the script to work well on systems
where the OpenStack-Ansible repositories aren't already cloned.

Installation
============

Install two packages via pip:

.. code-block:: console

   pip install jinja2 pygithub3

Running the script
==================

Generating diffs
----------------

The script has two required arguments:

.. code-block:: shell

   ./osa-differ.py OLD_COMMIT NEW_COMMIT

Tags or commit SHAs can be used for ``OLD_COMMIT`` and ``NEW_COMMIT``.
Here are two examples:

.. code-block:: shell

   # Find changes between commits f7d0a73 (older) and e00d329 (newer)
   ./osa-differ.py f7d0a73 e00d329

   # Find changes between tags 13.1.4 and 13.2.0
   ./osa-differ.py 13.1.4 13.2.0

If you reach the GitHub API limit for unauthenticated users, you may see a 403
error like this one::

   requests.exceptions.HTTPError: 403 Client Error: Forbidden for url: <URL>

You can provide a GitHub API token by setting the ``GITHUB_TOKEN`` environment
variable and running the script again:

.. code-block:: shell

   export GITHUB_TOKEN=fe64e5bff33523tat32913f69c49fe93d664e3a0
   ./osa-differ.py 13.1.4 13.2.0

For more details on generating GitHub API tokens, see the documentation section
:ref:`generate-github-token` below.

Configuring the output
----------------------

By default, the report will contain changes to OpenStack-Ansible, OpenStack-
Ansible's independent roles, and the OpenStack projects that OpenStack-Ansible
downloads and builds.

However, the information about independent roles and OpenStack-Ansible roles
can be skipped with additional arguments:

.. code-block:: shell

   # Show only the changes in OpenStack projects
   ./osa-differ.py --projects-only 13.1.4 13.2.0

   # Show only the changes in OpenStack-Ansible independent roles
   ./osa-differ.py --roles-only 13.1.4 13.2.0

Troubleshooting
---------------

Enable the script's debug mode by adding ``-d`` or ``--debug`` to the command
line arguments:

.. code-block:: shell

   ./osa-differ.py --debug 13.1.4 13.2.0

This will print lots of diagnostic information about each request to GitHub and
will identify any requests which are taking a long time to complete.

Appendix
========

.. _generate-github-token:

Generating GitHub API tokens
----------------------------

To generate a GitHub *personal access token*, follow these steps:

#. Authenticate to your GitHub account.

#. Access the *Personal access tokens* page: https://github.com/settings/tokens

#. Click on **Generate new token**. (You may be asked to provide your
   password.)

#. Enter a name for the token and click **Generate token**. (Leave all check
   boxes unchecked.)

#. Copy your new token and store it in safe place. GitHub won't display it
   again, so be sure to save it or you will need to generate another token.

#. Provide that token in the ``GITHUB_TOKEN`` environment variable before
   running the ``osa-differ.py`` script.
