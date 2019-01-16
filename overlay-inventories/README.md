# Overlay Ansible inventories

To deploy any of the operational tooling within an existing OpenStack-Ansible
deployment environment, or any environment that is using Ansible, it's
possible to use an overlay inventory to deploy systems without having to make
configuration changes in an environment or it's given inventory.

> An overlay inventory is nothing more than a second inventory source which
  contains meta groups that reference other groups as children.

This project folder contains reference overlay inventories that can be used
to deploy all of the tested operational tooling.

####### What's currently included

* elk_metrics_6x
* grafana
* osquery
* skydive

#### Deploying | The environment

The example overlay inventory file `osa-integration-inventory.yml` in this
directory is being used in this example to deploy all of the operational
tooling in an already online OpenStack-Ansible deployed cloud.

> The use of overlay inventories requires modern versions of Ansible. In
  this deployment example the embedded Ansible solution is being used to
  ensure all of the requirements are met.

``` shell
# Clone this repo into place
git clone https://github.com/openstack/openstack-ansible-ops /opt/openstack-ansible-ops

# Source the embedded ansible
source /opt/openstack-ansible-ops/bootstrap-embedded-ansible/bootstrap-embedded-ansible.sh

# Deploy osquery and kolide/fleet
pushd /opt/openstack-ansible-ops/osquery
    ansible-galaxy install -r ansible-role-requirements.yml
    ansible-playbook -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                     -i /opt/openstack-ansible-ops/overlay-inventories/osa-integration-inventory.yml \
                     -e @/etc/openstack_deploy/user_secrets.yml \
                     site.yml
popd

# Deploy the elastic-stack
pushd /opt/openstack-ansible-ops/elk_metrics_6x
    ansible-galaxy install -r ansible-role-requirements.yml
    ansible-playbook -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                     -i /opt/openstack-ansible-ops/overlay-inventories/osa-integration-inventory.yml \
                     -e @/etc/openstack_deploy/user_secrets.yml \
                     site.yml
popd

# Deploy skydive
pushd /opt/openstack-ansible-ops/skydive
    ansible-galaxy install -r ansible-role-requirements.yml
    ansible-playbook -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                     -i /opt/openstack-ansible-ops/overlay-inventories/osa-integration-inventory.yml \
                     -e @/etc/openstack_deploy/user_secrets.yml \
                     site.yml
popd

# Deploy grafana
pushd /opt/openstack-ansible-ops/grafana
    ansible-galaxy install -r ansible-role-requirements.yml
    ansible-playbook -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                     -i /opt/openstack-ansible-ops/overlay-inventories/osa-integration-inventory.yml \
                     -e @/etc/openstack_deploy/user_secrets.yml \
                     -e @/opt/openstack-ansible-ops/elk_metrics_6x/vars/variables.yml \
                     site.yml -e grafana_use_provisioning=no -e grafana_admin_password=secrete
popd

# Disable the embedded ansible post deployment
deactivate

# If using haproxy, run the haproxy playbook using the multiple inventory sources.
pushd /opt/openstack-ansible/playbooks
    openstack-ansible -i /opt/openstack-ansible/inventory/dynamic_inventory.py \
                      -i /opt/openstack-ansible-ops/overlay-inventories/osa-integration-inventory.yml \
                      -e @/etc/openstack_deploy/user_secrets.yml \
                      haproxy-install.yml
popd
```
