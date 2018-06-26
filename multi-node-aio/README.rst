OpenStack-Ansible Multi-Node AIO
################################
:date: 2016-03-09
:tags: rackspace, openstack, ansible
:category: \*openstack, \*nix


About this repository
---------------------

Full OpenStack deployment using a single OnMetal host from the
Rackspace Public Cloud. This is a multi-node installation using
VMs that have been PXE booted which was done to provide an environment
that is almost exactly what is in production. This script will build, kick
and deploy OpenStack using KVM, OpenStack-Ansible within 12 Nodes
and 1 load balancer all using a Hyper Converged environment.


Process
-------

Create at least one physical host that has public network access and is running
the Ubuntu 14/6.04 LTS Operating system. System assumes that you have an
unpartitioned device with at least 1TB of storage, however you can customize the
size of each VM volume by setting the option ``${VM_DISK_SIZE}``. If you're
using the Rackspace OnMetal servers the drive partitioning will be done for you
by detecting the largest unpartitioned device. If you're doing the deployment on
something other than a Rackspace OnMetal server you may need to set the
``${DATA_DISK_DEVICE}`` variable accordingly. the playbooks will look for a
volume group named "vg01", if this volume group exists no partitioning or setup
on the data disk will take place. To effectively use this process for testing
it's recommended that the host machine have at least 32GiB of RAM.

===========    ========   ============
Physical Host Specs known to work well
--------------------------------------
 CPU CORES      MEMORY     DISK SPACE
===========    ========   ============
    20           124GB       1.3TB
===========    ========   ============

These specs are covered by the Rackspace OnMetal-IO v1/2 Servers.

When your ready, run the build script by executing ``bash ./build.sh``. The
build script current executes a deployment of OpenStack Ansible using the master
branch. If you want to do something other than deploy master you can set the
``${OSA_BRANCH}`` variable to any branch, tag, or SHA.


Post Deployment
---------------

Once deployed you can use virt-manager to manage the KVM instances on the host,
similar to a DRAC or ILO.

LINUX:
    If you're running a linux system as your workstation simply install
    virt-manager from your package manager and connect to the host via
    QEMU/KVM:SSH

OSX:
    If you're running a MAC you can install https://www.xquartz.org/ to have
    access to a X11 client, then make use of X over SSH to connect to the
    virt-manager application. Using X over SSH is covered in
    https://www.cyberciti.biz/faq/apple-osx-mountain-lion-mavericks-install-xquartz-server/

WINDOWS:
    If you're running Windows, you can install virt-viewer from the KVM Download
    site.
    https://virt-manager.org/download/


Deployment screenshot
^^^^^^^^^^^^^^^^^^^^^

.. image:: screenshots/virt-manager-screenshot.jpeg
    :scale: 50 %
    :alt: Screen shot of virt-manager and deployment in action
    :align: center

Deployments can be accessed and monitored via virt-manager


Console Access
^^^^^^^^^^^^^^

.. image:: screenshots/console-screenshot.jpeg
    :scale: 50 %
    :alt: Screen shot of virt-manager console
    :align: center

The root password for all VMs is "**secrete**". This password is being set
within the pre-seed files under the "Users and Password" section. If you want
to change this password please edit the pre-seed files.


``build.sh`` Options
--------------------

Set an external inventory used for the MNAIO:
  ``MNAIO_INVENTORY=${MNAIO_INVENTORY:-playbooks/inventory}``


Set to instruct the preseed what the default network is expected to be:
  ``DEFAULT_NETWORK="${DEFAULT_NETWORK:-eth0}"``

Set the VM disk size in gigabytes:
  ``VM_DISK_SIZE="${VM_DISK_SIZE:-252}"``


Instruct the system do all of the required host setup:
  ``SETUP_HOST=${SETUP_HOST:-true}``

Instruct the system do all of the required PXE setup:
  ``SETUP_PXEBOOT=${SETUP_PXEBOOT:-true}``

Instruct the system do all of the required DHCPD setup:
  ``SETUP_DHCPD=${SETUP_DHCPD:-true}``


Instruct the system to Kick all of the VMs:
  ``DEPLOY_VMS=${DEPLOY_VMS:-true}``

Instruct the VM to use the selected image, eg. ubuntu-16.04-amd64:
  ``DEFAULT_IMAGE=${DEFAULT_IMAGE:-ubuntu-16.04-amd64}``

Instruct the VM to use the selected kernel meta package, eg. linux-generic:
  ``DEFAULT_KERNEL=${DEFAULT_KERNEL:-linux-image-generic}``

Set the OSA repo for this script to retrieve:
  ``OSA_REPO=${OSA_REPO:-https://git.openstack.org/openstack/openstack-ansible}``

Set the OSA branch for this script to deploy:
  ``OSA_BRANCH=${OSA_BRANCH:-master}``

Instruct the system to deploy OpenStack Ansible:
  ``DEPLOY_OSA=${DEPLOY_OSA:-true}``

Instruct the system to pre-config the envs for running OSA playbooks:
  ``PRE_CONFIG_OSA=${PRE_CONFIG_OSA:-true}``

Instruct the system to run the OSA playbooks, if you want to deploy other OSA
powered cloud, you can set it to false:
  ``RUN_OSA=${RUN_OSA:-true}``

Instruct the system to configure the completed OpenStack deployment with some
example flavors, images, networks, etc.:
  ``CONFIGURE_OPENSTACK=${CONFIGURE_OPENSTACK:-true}``

Instruct the system to configure iptables prerouting rules for connecting to
VMs from outside the host:
  ``CONFIG_PREROUTING=${CONFIG_PREROUTING:-true}``

Insrtuct the system to use a different Ubuntu mirror:
  ``DEFAULT_MIRROR_HOSTNAME=${DEFAULT_MIRROR_HOSTNAME:-archive.ubuntu.com}``

Instruct the system to use a different Ubuntu mirror base directory:
  ``DEFAULT_MIRROR_DIR=${DEFAULT_MIRROR_DIR:-/ubuntu}``

Instruct the system to use a set amount of ram for cinder VM type:
  ``CINDER_VM_SERVER_RAM=${CINDER_VM_SERVER_RAM:-2048}``

Instruct the system to use a set amount of ram for compute VM type:
  ``COMPUTE_VM_SERVER_RAM=${COMPUTE_VM_SERVER_RAM:-8196}``

Instruct the system to use a set amount of ram for infra VM type:
  ``INFRA_VM_SERVER_RAM=${INFRA_VM_SERVER_RAM:-8196}``

Instruct the system to use a set amount of ram for load balancer VM type:
  ``LOADBALANCER_VM_SERVER_RAM=${LOADBALANCER_VM_SERVER_RAM:-1024}``

Instruct the system to use a set amount of ram for the logging VM type:
  ``LOGGING_VM_SERVER_RAM=${LOGGING_VM_SERVER_RAM:-1024}``

Instruct the system to use a set amount of ram for the swift VM type:
  ``SWIFT_VM_SERVER_RAM=${SWIFT_VM_SERVER_RAM:-1024}``

Instruct the system to use a customized iPXE kernel:
  ``IPXE_KERNEL_URL=${IPXE_KERNEL_URL:-'http://boot.ipxe.org/ipxe.lkrn'}``

Instruct the system to use a customized iPXE script during boot of VMs:
  ``IPXE_PATH_URL=${IPXE_PATH_URL:-''}``


Re-kicking VM(s)
----------------

Re-kicking a VM is as simple as stopping a VM, delete the logical volume, create
a new logical volume, start the VM. The VM will come back online, pxe boot, and
install the base OS.

.. code-block:: bash

    virsh destroy "${VM_NAME}"
    lvremove "/dev/mapper/vg01--${VM_NAME}"
    lvcreate -L 60G vg01 -n "${VM_NAME}"
    virsh start "${VM_NAME}"


To rekick all VMs, simply re-execute the ``deploy-vms.yml`` playbook and it will
do it automatically.

.. code-block:: bash

    ansible-playbook -i playbooks/inventory playbooks/deploy-vms.yml

Rerunning the build script
--------------------------

The build script can be rerun at any time. By default it will re-kick the entire
system, destroying all existing VM's.

Deploying OpenStack into the environment
----------------------------------------

While the build script will deploy OpenStack, you can choose to run this
manually. To run a basic deploy using a given branch you can use the following
snippet. Set the ansible option ``osa_branch`` or export the environment
variable ``OSA_BRANCH`` when using the build.sh script.

.. code-block:: bash

    ansible-playbook -i playbooks/inventory playbooks/deploy-osa.yml -vv -e 'osa_branch=master'


Snapshotting an environment before major testing
------------------------------------------------

Running a snapshot on all of the vms before doing major testing is wise as it'll
give you a restore point without having to re-kick the cloud. You can do this
using some basic ``virsh`` commands and a little bash.

.. code-block:: bash

    for instance in $(virsh list --all --name); do
      virsh snapshot-create-as --atomic --name $instance-kilo-snap --description "saved kilo state before liberty upgrade" $instance
    done


Once the previous command is complete you'll have a collection of snapshots
within all of your infrastructure hosts. These snapshots can be used to restore
state to a previous point if needed. To restore the infrastructure hosts to a
previous point, using your snapshots, you can execute a simple ``virsh``
command or the following bash loop to restore everything to a known point.

.. code-block:: bash

    for instance in $(virsh list --all --name); do
      virsh snapshot-revert --snapshotname $instance-kilo-snap --running $instance
    done

Using a file-based backing store with thin-provisioned VM's
-----------------------------------------------------------

If you wish to use a file-based backing store (instead of the default LVM-based
backing store) for the VM's, then set the following option before executing
``build.sh``.

.. code-block:: bash

    export MNAIO_ANSIBLE_PARAMETERS="-e default_vm_disk_mode=file"
    ./build.sh

If you wish to save the current file-based images in order to implement a
thin-provisioned set of VM's which can be saved and re-used, then use the
``save-vms.yml`` playbook. This will stop the VM's and save the files to
``/var/lib/libvirt/images/*-base.img``. Re-executing the ``deploy-vms.yml``
playbook afterwards will rebuild the VMs from those images.

.. code-block:: bash

    ansible-playbook -i playbooks/inventory playbooks/save-vms.yml
    ansible-playbook -i playbooks/inventory -e default_vm_disk_mode=file playbooks/deploy-vms.yml

To disable this default functionality when re-running ``build.sh`` set the
build not to use the snapshots as follows.

.. code-block:: bash

    export MNAIO_ANSIBLE_PARAMETERS="-e default_vm_disk_mode=file -e vm_use_snapshot=no"
    ./build.sh
