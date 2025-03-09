==================
Encrypting secrets
==================

This document describes the supported operations for encrypting secrets and explains how to perform them using the appropriate tooling.

Ansible-Vault
=============

OpenStack-Ansible provides tooling to encrypt and rotate secret files and keypairs using Ansible Vault.

Role Defaults
-------------

.. literalinclude:: ../../encrypt_secrets/roles/ansible_vault/defaults/main.yml
   :language: yaml
   :start-after: under the License.

Installing the Collection
-------------------------

To install the collection, define it in your region deployment configuration file, located at `/etc/openstack_deploy/user-collection-requirements.yml`, as shown below:

.. code-block:: yaml

  - name: osa_ops.encrypt_secrets
    type: git
    version: master
    source: https://opendev.org/openstack/openstack-ansible-ops#/encrypt_secrets

Then, run `./scripts/bootstrap-ansible.sh` to install the collection.

Initial Encryption of Secret Files
----------------------------------

When initializing a region for the first time, you should encrypt secrets and generated private keys before storing them in Git. You can perform this process locally or on the deployment host.

.. NOTE::

   You must re-run the encryption process whenever new services or keypairs are generated, which may occur at later deployment stages.

Encrypting Secrets Locally
~~~~~~~~~~~~~~~~~~~~~~~~~~

The process for encrypting secrets locally is similar to running it on the deploy host, but some context-specific variables required by OpenStack-Ansible may be unavailable and must be supplied manually.

Ensure you have a Python virtual environment with Ansible installed before proceeding.

1. Generate a password for the Ansible Vault and store it securely:

.. code-block:: bash

  pwgen 36 1 > /tmp/vault.secret

2. Run the encryption playbook:

.. code-block:: bash

  ansible-playbook osa_ops.encrypt_secrets.ansible_vault -e ansible_vault_region=${REGION_NAME} -e ansible_vault_pw=/tmp/vault.secret

3. Copy the contents of `/tmp/vault.secret` to the deployment host, for example to `/etc/openstack/vault.secret`.
4. Define the vault secret path in `/etc/openstack_deploy/user.rc`:

.. code-block:: bash

  export ANSIBLE_VAULT_PASSWORD_FILE=/etc/openstack/vault.secret

5. Store the password securely in your preferred password manager.
6. Push the changes to your Git repository.
7. Ensure that the deploy host decrypts any required secrets.

Encrypting Secrets on the Deployment Host
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

Follow these steps to encrypt secrets directly on the deployment host:

1. Generate a password and store it securely:

.. code-block:: bash

  pwgen 36 1 > /etc/openstack/vault.secret

2. Define the vault secret path in `/etc/openstack_deploy/user.rc`:

.. code-block:: bash

  export ANSIBLE_VAULT_PASSWORD_FILE=/etc/openstack/vault.secret

3. Run the encryption playbook:

.. code-block:: bash

  openstack-ansible osa_ops.encrypt_secrets.ansible_vault

4. Commit and push changes to `/etc/openstack_deploy` in your Git repository.
5. Save the vault password (`/etc/openstack/vault.secret`) in a secure password manager.
6. Decrypt any necessary secrets before running OpenStack playbooks.


Decrypting Keypairs on the Deploy Host
--------------------------------------

The OpenStack-Ansible PKI role does not support storing private keys in encrypted format on the deployment host. Instead, configure a pipeline that decrypts the keys after placing them on the deploy host.

Encrypted keypairs should be committed to the Git repository, but stored unencrypted on the deployment host.

To decrypt them, run the following playbook:

.. code-block:: bash

  openstack-ansible osa_ops.encrypt_secrets.ansible_vault -e ansible_vault_action=decrypt


Rotating the Ansible Vault Secret
---------------------------------

Rotating the Ansible Vault password requires re-encrypting all secrets in the repository. Assuming the original password is stored in `/tmp/vault.secret`, follow these steps:

1. Generate a new vault password/encryption key:

.. code-block:: bash

  pwgen 45 1 > /tmp/vault.secret.new

2. Re-encrypt all secrets using the new password:

.. code-block:: bash

  ANSIBLE_VAULT_PASSWORD_FILE=/tmp/vault.secret ansible-playbook osa_ops.encrypt_secrets.ansible_vault -e ansible_vault_action=rotate

3. Transfer the new password to the deployment host and store it securely in a password manager.
