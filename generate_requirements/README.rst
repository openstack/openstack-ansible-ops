Generate Requirements
=====================

This tool is will clone openstack-ansible, parse
ansible-role-requirements.yml, and clone the OpenStack-Ansible related
roles found therein.

After cloning, the tool will recursively parse each role's
dependencies as defined in meta/main.yml for each role.

This tools is intended to be used by maintainers of OpenStack-Ansible
to assist in generating requirements.yml files.

Usage
-----

To use this software, simply run ./run.sh
This will clone openstack-ansible into a child directory of the
current working directory (if it doesn't exist), checkout master,
run a pull, and proceed to download the other roles.

After all roles are downloaded, requirements.yml files will be
generated for each.
