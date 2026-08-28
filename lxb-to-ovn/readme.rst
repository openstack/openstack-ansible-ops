Example OpenStack conversion scripts from LXB to OVN
####################################################

WARNING
-------

These playbooks and variables are intended as an example only. No guarantees are provided that these will work correctly for your OpenStack deployment, or that the behaviour of these playbooks results in a correct, functional OVN deployment. Significant testing and great care is encouraged before using the approaches defined here in production systems.

Approach
--------

These playbooks are written in an opinionated fashion in order to migrate from a Linux Bridge (LXB) tenant networking setup, to one using Open Virtual Networking (OVN).

Virtual machines are live migrated from LXB hypervisors onto OVN hypervisors, ensuring VMs do not require any reboots, although their connectivity will see a period of interruption.

Given that the LXB and OVN implementations of VXLAN/GENEVE are fundamentally incompatible (for example using multicast vs ingress replication), there is a necessary period of downtime for all tenant networks. This prompted a design choice to migrate on a project by project basis, ensuring that downtime for each tenant is minimal. This has the trade off that the migration is slightly more complex for the administrator, as LXB must remain a little more functional to manage capacity on hypervisors during the migration process.

An alternative approach which works on a hypervisor-by-hypervisor basis would not require neutron-server to run the OVN and LXB plugins at the same time, but would result in longer periods of inaccessibility between project VMs, and increases pressure to resolve issues if these are encountered mid-way through a migration.

Caveats & References
--------------------

The approach used here has been developed for a specific OpenStack deployment design, with steps taken identified through learning from others' experience and experimenting with the Neutron and OVN databases in a development environment. No guarantees are provided that this approach is correct or complete, so please use it at your own risk.

Thanks in particular to James Denton and the engineers at CERN for their pointers in the migration process:

* `https://www.jimmdenton.com/migrating-lxb-to-ovn/ <https://www.jimmdenton.com/migrating-lxb-to-ovn/>`_
* `https://techblog.web.cern.ch/techblog/tags/linuxbridge/ <https://techblog.web.cern.ch/techblog/tags/linuxbridge/>`_

Assumptions & Limitations
-------------------------

* OpenStack Ansible is used as a deployment tool, with LXB networking, LXC container based control plane, and L3 networking via network nodes which will be converted to OVN gateways rather than distributed virtual routing (DVR).
* LXB uses VLAN and/or VXLAN networking
* An appropriate MTU is set across any existing VXLAN infrastructure to accommodate GENEVE's larger header size (1558 rather than 1550 for example).
* A maximum of 4095 VXLAN networks are defined. Any greater than this will breach OVN's limits and requires it to operate in GEVENE only mode. Whilst it may be possible to migrate to this in a single step, our tested procedure involves moving to VXLAN first.
* Tested against an OpenStack Dalmatian 2024.2 deployment.

Required Patches
----------------

The following patch intends to allow LXB to remain partially functional whilst migrating to OVN. This is intended to ensure LXB to LXB hypervisor live migration still works during the process, but provides no guarantees of functionality beyond this:

* `https://github.com/bbc/neutron/commit/3282e93bc6f9b24e4852f2125c4b19185db17472 <https://github.com/bbc/neutron/commit/3282e93bc6f9b24e4852f2125c4b19185db17472>`_

In addition, ensure that linuxbridge remains as a secondary driver following ovn in the mechanism_drivers list. Note that when LXB isn't the primary driver, we need to explicitly set the experimental flag in neutron.conf.

.. code-block:: ml2_conf.ini

    mechanism_drivers = ovn,linuxbridge

We also found the following patches to be important, but this may vary dependent on the Neutron features which your deployment uses.

* `https://review.opendev.org/c/openstack/openstack-ansible-os_neutron/+/941351 <https://review.opendev.org/c/openstack/openstack-ansible-os_neutron/+/941351>`_
* `https://review.opendev.org/c/openstack/openstack-ansible-os_neutron/+/1001462 <https://review.opendev.org/c/openstack/openstack-ansible-os_neutron/+/1001462>`_
* `https://review.opendev.org/c/openstack/neutron/+/942156 <https://review.opendev.org/c/openstack/neutron/+/942156>`_

Sample Variables
----------------
See `sample_osa_vars.yml` and `sample_provider_networks.yml` for examples of how OVN and LXB are configured in parallel, with a `_neutron_host_type` variable used to switch hypervisors and network nodes between these modes.

Procedure
---------

Before starting, ensure your database is backed up. Restoring would be difficult, but it would at least allow you to identify where changes had been made. Additionally, make sure users or automated systems cannot make changes to Neutron resources, potentially by disabling access in Keystone.

Ensure you are running these playbooks from a host with access to:

* SSH to your OVN and Galera databases
* SSH to your hypervisors and network nodes
* Ping your tenant network routers' external IPs (v4 and v6)

These playbooks are not directly written to be run from your OpenStack Ansible deployment host, but could be modified to support this scenario.

1) Free up one or more hypervisors which will be converted to OVN first and act as migration targets for LXB VMs.

2) Free up one or more network nodes (running `neutron-l3-agent`) which will be converted to OVN first. Stop `neutron-l3-agent` and fail over any tenant routers on these nodes by killing associated processes, in particular `keepalived`.

3) Deploy the OVN database container using OpenStack Ansible. Use a suitable limit to include only the OVN Northd containers, and set `-e neutron_plugin_type=ml2.ovn`

4) Patch `neutron-server` instances to better support running OVN at the same time as LXB (see PATCHES).

5) Modify the hostnames and container names for the OVN database and the Galera database in the following, along with the Neutron external network ID:

* `disable_ovn_lrp.yml`
* `migrate_to_ovn.yml`
* `convert_vxlan_to_geneve.yml`

6) Set `lb_enabled` to true if you run Octavia, and `excluded_projects` to include the project which Octavia uses in `migrate_to_ovn.yml`.

7) Set `fw_enabled` to true if you run Neutron FWaaS.

8) Set `l3_agents` to a list of hosts which run `neutron-l3-agent` and haven't yet been migrated to OVN. This list will need to be adjusted during the migration process.

9) Disable the external facing network interface on the network network node(s) to be converted to OVN, either on the server or its connected switch.

10) Disable user access to the OpenStack control plane to prevent changes from being made.

11) Convert at least one instance of `neutron-server` to OVN, using the Neutron configuration above. Ensure LXB remains active as a secondary ML2 plugin. You may choose to convert all `neutron-server` instances at this stage, or leave some in an LXB only mode but with their service stopped so they can be available as a fallback.

12) Synchronise the OVN database with Neutron by running `/openstack/venvs/neutron-${DISTRIB_RELEASE}/bin/neutron-ovn-db-sync-util --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --ovn-neutron_sync_mode repair` from the `neutron-server` container. Watch the logs when performing this as if it exits early with a CRITICAL error this will need to be investigated.

* Then run it again and watch for things it claims to be creating. This indicates there is a persistent issue creating them or setting their properties.
* Ensure no OVN errors are being output from neutron-server logs after this has run - this should fix any errors that existed before.

13) Run `disable_ovn_lrp.yml`. This disables tenant router external ports and prevents GARP packets from being issued before we are ready for them.

14) Run `cleanup_lxb_interfaces.yml` against the freed up hosts.

15) Convert the freed up hypervisors and network nodes to OVN using OpenStack Ansible. In particular, the following must be set to new values, but only for the hosts to be changed:

* `neutron_plugin_type` - set to `ml2.ovn`
* `neutron_plugin_base` - replace `router` with `ovn-router`
* `neutron_provider_networks` - in particular, set `network_mappings` and `network_interface_mappings` correctly
* Note that if a network node was running the BGP dynamic routing agent, any BGP speakers will need to be re-associated with it to re-establish sessions.

16) Enable the external facing network interface on your OVN network node(s), either on the server or its connected switch.

17) Disable all LXB hypervisors, but leave their services running

18) Run `migrate_to_ovn.yml`.

19) When the first VM fails to migrate and the playbook pauses, free up one or more additional hypervisors. This will require you to temporarily re-enable LXB hypervisors, move VMs between them, and then disable them again.

20) Next, run `cleanup_lxb_interfaces.yml` against these hypervisors, migrate them to OVN using the instructions above, and enable their compute service. Migrate the VM which failed to migrate manually to ensure it now succeeds, then allow the playbook to continue which will fix the migrated VM's networking.

21) Repeat this process until the migration playbook completes. If the playbook fails it can be re-run, but it will repeat some steps for projects which have already been migrated. Note however that failure between completing a VM migration and fixing its networking will not be re-attempted and would need to be manually addressed.

22) Convert any remaining hypervisors to OVN as noted above.

23) Convert any remaining network nodes to OVN as noted above.

24) Convert any remaining `neutron-server` instances to OVN. The LXB secondary driver can now be removed.

25) Run `cleanup_lxb_agents.yml` to delete records of LXB agents from OpenStack, and run `cleanup_ovn_bridges.yml` against all hypervisors to clean up some LXB remnants from VM migrations.

26) Review the Neutron database, in particular `neutron_ml2_port_bindings` and `neutron_ml2_port_binding_levels` for entities still listing 'bridge' or 'linuxbridge' and amend as appropriate.

27) Re-synchronise the OVN database with Neutron by running `/openstack/venvs/neutron-${DISTRIB_RELEASE}/bin/neutron-ovn-db-sync-util --config-file /etc/neutron/neutron.conf --config-file /etc/neutron/plugins/ml2/ml2_conf.ini --ovn-neutron_sync_mode repair` from the `neutron-server` container. This is necessary to ensure that manual database changes are properly reflected, mostly relating to LXB metadata ports.

28) Run `convert_vxlan_to_geneve.yml` to convert Neutron's database to consider tenant networks as Geneve. This doesn't appear to have any practical impact on OVN itself which decides between using VXLAN or Geneve based on the tunnel type it is configured to use. However, if you use a segmentation ID greater than 4095, this is a necessary step to avoid hitting Neutron validation issues. Similarly, if you wish to use more than 4095 IDs, OVN will need to be switched to Geneve only mode.
