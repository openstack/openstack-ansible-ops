tftpboot_configure
=========

This module configures custom tftp allowing for netboot of an Ubuntu system. It dynamically creates a TFTBoot based on the MAC addresses passed in. It also generates a preseed and late command which are used to install the system

Requirements
------------

This module requires Ansible 2.x

Role Variables
--------------

See defaults for variables and descriptions

Dependencies
------------

This role depends on a DHCPD and ATFTP roles

Example Playbook
----------------

Example to call:

    - hosts: all
      roles:
         - { role: tftpboot_configure }
