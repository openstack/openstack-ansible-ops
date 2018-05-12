OpenStack-Ansible pxelinux Provisioning
#######################################
:date: 2018-04-24
:tags: rackspace, openstack, ansible
:category: \*openstack, \*nix


About this repository
---------------------

This repository provides for basic "pxelinux" provisioning using debian based
operating systems.

A complete set of options can be seen within the ``playbook/group_vars/all.yml``
file.

These provisioning playbooks have been created to use static inventory. Example
static inventory used for these playbooks can be seen in the
``playbooks/inventory.yml`` file.

Scripts have been created to simplify the deployment of these playbooks and
install ansible however they are 100% optional.


Playbook Usage
--------------

These playbooks require three groups, ``dhcp_hosts``, ``pxe_hosts``, and
``pxe_servers``. The groups ``dhcp_hosts`` and ``pxe_hosts`` are used as targets
to install the required packages and setup the TFTP and DHCP services. The group
``pxe_servers`` is as a set of targets that to deploy a given OS.

Each host in the ``pxe_servers`` group should have the something similar to the
following configuration.

.. code-block:: yaml

    $name_used_in_inventory:
      ansible_os_family: "{{ default_images[default_image_name]['image_type'] }}"
      server_hostname: '$hostname'
      server_image: "ubuntu-18.04-amd64"
      server_default_interface: 'eth0'
      server_obm_ip: 192.168.1.100
      server_model: PowerEdge R710
      server_mac_address: 00:11:22:33:44:55
      server_extra_options: ''
      server_fixed_addr: "10.0.0.100"
      server_domain_name: "{{ default_server_domain_name }}"
      ansible_host: "{{ server_fixed_addr }}"

The options **$name_used_in_inventory** and **$hostname** need to be changed to
reflect the machine being deployed as well as the ``server_mac_address`` and
``server_obm_ip`` entries. Note ``server_obm_ip`` is  optional and not a
required attribute.

With the inventory all setup the script ``build.sh`` can be used to deploy
everything or the playbooks could be run with the following commmand.

.. code-block:: bash

    ansible-playbook -vv -i /root/inventory.yml
                         -e setup_host=${SETUP_HOST:-"true"}
                         -e setup_pxeboot=${SETUP_PXEBOOT:-"true"}
                         -e setup_dhcpd=${SETUP_DHCPD:-"true"}
                         -e default_image=${DEFAULT_IMAGE:-"ubuntu-18.04-amd64"}
                         -e default_http_proxy=${DEFAULT_HTTP_PROXY:-''}
                         --force-handlers
                         playbooks/site.yml

Once the playbooks have completed, set the ``pxe_servers`` target hosts, PXE
boot once and reboot them.

For convience a playbook named ``playbooks/idrac-config.yml`` has been added
which will do **minimal** drac reset and re-configuration which will result in
the host being ready to PXE. This playbook is **not** intended for production
use and was included **only** as an example.
