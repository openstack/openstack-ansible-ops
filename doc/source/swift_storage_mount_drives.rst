===================================================================
OpenStack-Ansible Swift Mount drives in storage nodes Documentation
===================================================================

Playbook under the folder

ansible_tools/playbooks/swift_storage_mount_drives.yml

This playbook mainly helps to mount the drives in swift object nodes,
if not prior mounted and formatted.

The steps it performs are:
  - Format the disks mentioned in swift configuration file
    in openstack-ansible to the filesystem mentioned in the playbook
    (editable by the end-user in playbook).
  - Mount the drives to the device-path(mentioned in the playbook
    and is editable) like /dev/sdb or /opt/sdb or /openstack/sdb.

This removes the manual effort of mounting and makes the swift users
life easier by mounting the devices.

How to run the playbook
=======================

ansible-playbook ansible_tools/playbooks/swift_storage_mount_drives.yml

This will mount all the drives in the swift object nodes
