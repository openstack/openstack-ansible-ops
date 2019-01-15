# Skydive Ansible deployment

These playbooks and roles will deploy skydive, a network topology and
protocols analyzer.

Official documentation for skydive can be found here:
http://skydive.network/documentation/deployment#ansible

----

## Overview

The playbooks provide a lot of optionality. All of the available options are
within the role `defaults` or `vars` directories and commented as nessisary.

The playbooks are roles contained within this repository will build or GET
skydive depending on how the inventory is setup. If build services are
specified, skydive will be built from source using the provided checkout
(default HEAD). Once the build process is complete, all skydive created
binaries will be fetched and deployed to the target agent and analyzer
hosts.

Skydive requires a persistent storage solution to store data about the
environment and to run captures. These playbooks require access to an
existing Elasticsearch cluster. The variable `skydive_elasticsearch_uri`
must be set in a variable file, or on the CLI at the time of deployment.
*If this option is undefined the playbooks will not run*.

A user password for skydive and the cluster must be defined. This option can
be set in a variable file or on the CLI. If this option is undefined the
playbooks will not run.

Once the playbooks have been executed, the UI and API can be accessed via a
web browser or CLI on port `8082` on the nodes running the **Analyzer**.

### Balancing storage traffic

Storage traffic is balanced on each analyzer node using a reverse proxy/load
balancer application named [Traefik](https://docs.traefik.io). This system
provides a hyper-light weight, API-able, load balancer. All storage traffic
will be sent through Traefik to various servers within the backend. This
provides access to a highly available cluster of Elasticsearch nodes as
needed.

### Deploying binaries or building from source

This deployment solution provides the ability to install skydive from source
or from pre-constructed binaries. The build process is also available for
the traefik loadbalancer.

The in cluster build process is triggered by simply having designated build
nodes within the inventory. If `skydive_build_nodes` or `traefik_build_nodes`
is defined in inventory the build process for the selected solution will be
triggered. Regardless of installation preference, the installation process is
the same. The playbooks will `fetch` the binaries and then ship them out the
designated nodes within inventory. A complete inventory example can be seen
in the **inventory** directory.

#### Deploying | Installing with embedded Ansible

If this is being executed on a system that already has Ansible installed but is
incompatible with these playbooks the script `bootstrap-embedded-ansible.sh`
can be sourced to grab an embedded version of Ansible prior to executing the
playbooks.

``` shell
source bootstrap-embedded-ansible.sh
```

#### Deploying | Manually resolving the dependencies

This playbook has external role dependencies. If Ansible is not installed with
the `bootstrap-embedded-ansible.sh` script these dependencies can be resolved
with the ``ansible-galaxy`` command and the ``ansible-role-requirements.yml``
file.

``` shell
ansible-galaxy install -r ansible-role-requirements.yml
```

Once the dependencies are set make sure to set the action plugin path to the
location of the config_template action directory. This can be done using the
environment variable `ANSIBLE_ACTION_PLUGINS` or through the use of an
`ansible.cfg` file.

#### Deploying | The environment natively

The following example will use a local inventory, and set the required options
on the CLI to run a deployment.

``` shell
ansible-playbook -i inventory/inventory.yml \
                 -e skydive_password=secrete \
                 -e skydive_elasticsearch_servers="172.17.24.8,172.17.24.9" \
                 site.yml
```

Tags are available for every playbook, use the `--list-tags`
switch to see all available tags.


#### Deploying | The environment within OSA

While it is possible to integrate skydive into an OSA cloud using environment
extensions and `openstack_user_config.yml` additions, the deployment of this
system is possible through the use of an inventory overlay.

> The example overlay inventory file `inventory/osa-integration-inventory.yml`
  assumes elasticsearch is already deployed and is located on the baremetal
  machine(s) within the log_hosts group. If this is not the case, adjust the
  overlay inventory for your environment.

> The provided overlay inventory example makes the assumption that skydive
  leverage the same

``` shell

# Source the embedded ansible
source bootstrap-embedded-ansible.sh

# Run the skydive deployment NOTE: This is using multiple inventories.
ansible-playbook -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                 -i /opt/openstack-ansible/ops/skydive/inventory/osa-integration-inventory.yml \
                 -e @/etc/openstack_deploy/user_secrets.yml \
                 site.yml

# Disable the embedded ansible
deactivate

# If using haproxy, run the haproxy playbook using the multiple inventory sources.
cd /opt/openstack-ansible/playbooks
openstack-ansible -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                  -i /opt/openstack-ansible/ops/skydive/inventory/osa-integration-inventory.yml \
                  haproxy-install.yml
```

##### Configuration | Haproxy

The example overlay inventory contains a section for general haproxy
configuration which exposes the skydive UI internally.

> If the deployment has `haproxy_extra_services` already defined the following
  extra haproxy configuration will needed to be appended to the existing user
  defined variable.

``` yaml
- service:
    haproxy_service_name: skydive_analyzer
    haproxy_backend_nodes: "{{ groups['skydive_analyzers'] | default([]) }}"
    haproxy_bind: "{{ [internal_lb_vip_address] }}"
    haproxy_port: 8082
    haproxy_balance_type: http
    haproxy_ssl: true
    haproxy_backend_options:
      - "httpchk HEAD / HTTP/1.0\\r\\nUser-agent:\\ osa-haproxy-healthcheck"
- service:
    haproxy_service_name: traefik
    haproxy_backend_nodes: "{{ groups['skydive_analyzers'] | default([]) }}"
    haproxy_bind: "{{ [internal_lb_vip_address] }}"
    haproxy_port: 8090
    haproxy_balance_type: http
    haproxy_ssl: true
    haproxy_backend_options:
      - "httpchk HEAD / HTTP/1.0\\r\\nUser-agent:\\ osa-haproxy-healthcheck"
```

This config will provide access to the web UI for both **skydive** and
**traefik**.

* Skydive runs on port `8082`
* Traefik runs on port `8090`

### Validating the skydive installation

Post deployment, the skydive installation can be valided by simply running the
`validateSkydive.yml` playbook.

----

TODOs:
* Setup cert based agent/server auth
* Add openstack integration
** document openstack integration, what it adds to the admin service
