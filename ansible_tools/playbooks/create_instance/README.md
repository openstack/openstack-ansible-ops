Role Name
=========

A brief description of the role goes here.

Requirements
------------

Any pre-requisites that may not be covered by Ansible itself or the role should be mentioned here. For instance, if the role uses the EC2 module, it may be a good idea to mention in this section that the boto package is required.

Role Variables
--------------

A description of the settable variables for this role should go here, including any variables that are in defaults/main.yml, vars/main.yml, and any variables that can/should be set via parameters to the role. Any variables that are read from other roles and/or the global scope (ie. hostvars, group vars, etc.) should be mentioned here as well.

Dependencies
------------

A list of other roles hosted on Galaxy should go here, plus any details in regards to parameters that may need to be set for other roles, or variables that are used from other roles.

Example Playbook
----------------

Including an example of how to use your role (for instance, with variables passed in as parameters) is always nice for users too:

    - hosts: servers
      roles:
         - { role: username.rolename, x: 42 }
# Requirements
The below requirements are needed on the host that executes this module.

* openstacksdk

* openstacksdk >= 0.12.0

* python >= 3.6

```
ansible-galaxy collection install openstack.cloud

```
# preconfig

you need to add config this file and change parameters

```
 vim defaults/main.yml

```
```
# defaults file for create_instance
auth_url:  "https://cloud.iranserver.com:5000/v3"
username: "rezabojnordi"
password: "123456"
project_name: "reza"
image: "image id"
##count: "1"
key_name: "rb"
flavor: "flavor id"
net_id: "flavor id"
net_name: ""

```

# Run Plabook
```
ansible-playbook -i hosts --tags instance_lunch -e 'machine=local' create_instance.yml
```

License
-------

BSD

Author Information
------------------

An optional section for the role authors to include contact information, or a website (HTML is not allowed).
