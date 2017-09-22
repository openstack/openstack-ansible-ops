# OpenStack-Ansible leap upgrade

## Jump upgrade using OpenStack-Ansible for Ubuntu 14.04

==**This currently a POC**==

### Uses

This utility can be used to upgrade any OpenStack-Ansible deployment running
Juno / Kilo to the Newton release 14.2.3. The process will upgrade the system
components, sync the database through the various releases, and then deploy
OSA using the Newton release. While this method will help a deployment skip
several releases deployers should be aware that skipping releases is not
something OpenStack supports. To make this possible the active cloud will
have the OpenStack services stopped. Active workloads "*should*" remain online
for the most part though at this stage no effort is being put into maximizing
uptime as the tool set is being developed to easy multi-release upgrades in
the shortest possible time while maintaining data-integrity.

#### Requirements

  * **You must** have a Juno/Kilo based OpenStack cloud as deployed by
    OpenStack-Ansible.
  * If you are running cinder-volume with LVM in an LXC container **you must**
    migrate the cinder-volume service to the physical host.
  * **You must** have the Ubuntu Trusty Backports repo enabled on all hosts before you start.

#### Limitations

  * Upgrading old versions of "libvirt-bin<=1.1" to newer versions of
    "libvirt-bin>=1.3" in a single step can cause VM downtime.
  * L3 networks may experience an outage as routers and networks are
    rebalanced throughout the environment.

#### Recommendations

  * It is recommended all physical hosts be updated to the latest patch release.
    This can be done using standard package manager tooling.

#### Process

If you need to run everything the script ``run-stages.sh`` will execute
everything needed to migrate the environment.

``` bash
bash ./run-stages.sh
```

If you want to pre-load the stages you can do so by running the various scripts
independently. **You must** export ``export UPGRADES_TO_TODOLIST`` once the
prep.sh script is completed.

``` bash
bash ./prep.sh
bash ./upgrade.sh
bash ./migrations.sh
bash ./re-deploy.sh
```

Once all of the stages are complete the cloud will be running OpenStack
Newton.

----

### Example leap with a multi-node juno environment.

Testing on a multi-node environment can be accomplished using the
https://github.com/openstack/openstack-ansible-ops/tree/master/multi-node-aio
repo. To create this environment for testing a single physical host can be
used; Rackspace OnMetal V1 deployed Ubuntu 14.04 on an IO flavor has worked
very well for development. To run the deployment execute the following commands

#### Requirements

  * When testing, the host will need to start with Kernel less than or equal to "3.13". Later
    kernels will cause neutron to fail to run under the Juno code base.
  * Start the deployment w/ ubuntu 14.04.2 to ensure the deployment version is
    limited in terms of package availability.

#### Setup a multi-node AIO

Clone the ops tooling and change directory to the multi-node-aio tooling

``` bash
git clone https://github.com/openstack/openstack-ansible-ops /opt/openstack-ansible-ops
```

Run the following commands to prep the environment.

``` bash
cd /opt/openstack-ansible-ops/multi-node-aio
setup-host.sh
setup-cobbler.sh
setup-virsh-net.sh
deploy-vms.sh
```

#### Deploy an example Juno config

After the environment has been deployed clone the RPC configurations which support Juno
based clouds.

``` bash
git clone https://github.com/os-cloud/leapfrog-juno-config /etc/rpc_deploy
```

#### Deploy Juno

Now clone the Juno playbooks into place.

``` bash
git clone --branch leapfrog https://github.com/os-cloud/leapfrog-juno-playbooks /opt/openstack-ansible
```

Finally, run the bootstrap script and the haproxy and setup playbooks to deploy the cloud environment.

``` bash
cd /opt/openstack-ansible
./scripts/bootstrap-ansible.sh

cd rpc_deployment
openstack-ansible playbooks/haproxy-install.yml
openstack-ansible playbooks/setup-everything.yml
```

#### Test your Juno cloud

To test the cloud's functionality you can execute the OpenStack resource test script located in the scripts directory
of the playbooks cloned earlier.

``` bash
cd /opt/openstack-ansible/rpc_deployment
ansible -m script -a /opt/openstack-ansible/scripts/setup-openstack-for-test.sh 'utility_all[0]'
```

The previous script will create the following:

  * New flavors
  * Neutron L2 and L3 networks
  * Neutron routers
  * Setup security groups
  * Create test images
  * 2 L2 network test VMs
  * 2 L3 network test VMs w/ floating IPs
  * 2 Cinder-volume test VMs
  * 2 new cinder volumes which will be attached to the Cinder-volume test VMs
  * Upload an assortment of files into a Test-Swift container

Once the cloud is operational it's recommended that images be created so that the environment can be
reverted to a previous state should there ever be a need. See
https://github.com/openstack/openstack-ansible-ops/tree/master/multi-node-aio#snapshotting-an-environment-before-major-testing
for more on creating snapshots.

#### Run the leapfrog

See the "Process" part on the top of the page
