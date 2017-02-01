atftpd_install
=========

This module installs atftpd and allows you to set the path of where it reads tftp from

Requirements
------------

This module requires Ansible 2.0

Role Variables
--------------

See defaults for variables and descriptions

Example Playbook
----------------

Example to call:

    - hosts: all
      roles:
         - { role: atftpd_install, atftpd_path: /tftpboot }
