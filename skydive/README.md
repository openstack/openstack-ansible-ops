# Skydive Ansible deployment

These playbooks and roles will deploy skydive, a network
topology and protocols analyzer.

Official documentation for skydive can be found here:
http://skydive.network/documentation/deployment#ansible

----

### Overview

The playbooks provide a lot of optionality. All of the
available options are within the role `defaults` or
`vars` directories and commented as nessisary.

The playbooks are roles contained within this repository
will build or GET skydive depending on how the inventory
is setup. If build services are specified, skydive will
be built from source using the provided checkout
(default HEAD). Once the build process is complete, all
skydive created binaries will be fetched and deployed to
the target agent and analyzer hosts.

Skydive requires a persistent storage solution to store
data about the environment and to run captures. These
playbooks require access to an existing Elasticsearch
cluster. The variable `skydive_elasticsearch_uri` must be
set in a variable file, or on the CLI at the time of
deployment. If this option is undefined the playbooks
will not run.

A user password for skydive and the cluster must be
defined. This option can be set in a variable file or
on the CLI. If this option is undefined the playbooks
will not run.

Once the playbooks have been executed, the UI and API
can be accessed via a web browser or CLI on port `8082`.

#### Balancing storage traffic

Storage traffic is balanced on each analyzer node using
a reverse proxy/load balancer application named
[Traefik](https://docs.traefik.io). This system
provides a hyper-light weight, API-able, load balancer.
All storage traffic will be sent through Traefik to
various servers within the backend. This provides access
to a highly available cluster of Elasticsearch nodes as
needed.

#### Deploying binaries or building from source

This deployment solution provides the ability to install
skydive from source or from pre-constructed binaries. The
build process is also available for the traefik loadbalancer.

The in cluster build process is triggered by simply having
designated build nodes within the inventory. If
`skydive_build_nodes` or `traefik_build_nodes` is defined in
inventory the build process for the selected solution will
be triggered. Regardless of installation preference, the
installation process is the same. The playbooks will `fetch`
the binaries and then ship them out the designated nodes
within inventory. A complete inventory example can be seen
in the **inventory** directory.

### Deployment Execution

The following example will use a local inventory, and
set the required options on the CLI.

``` shell
ansible-playbook -i inventory/inventory.yml \
                 -e skydive_password=secrete \
                 -e skydive_elasticsearch_servers="172.17.24.8,172.17.24.9" \
                 site.yml
```

Tags are available for every playbook, use the `--list-tags`
switch to see all available tags.


#### Validating the skydive installation

Post deployment, the skydive installation can be valided by
simply running the `validateSkydive.yml` playbook.

----

TODOs:
* Setup cert based agent/server auth
* Add openstack integration
** document openstack integration, what it adds to the admin service
