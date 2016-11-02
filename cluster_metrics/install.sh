# This script automatically installs the monitoring stack into a VM with an Openstack ansible all in one installed.

# clone custom openstack rpc-maas, we'll need it for telegraf configurations
cd /opt/
git clone https://github.com/osic/reliability-rpc-openstack.git

cd /opt/reliability-openstack-ansible-ops/cluster_metrics

echo 'Add the export to update the inventory file location'
export ANSIBLE_INVENTORY=/opt/openstack-ansible/playbooks/inventory/dynamic_inventory.py
echo 'done!'

echo 'Copy the env.d files in place'
mkdir -p /etc/openstack_deploy/env.d/
cp /opt/reliability-openstack-ansible-ops/cluster_metrics/etc/env.d/cluster_metrics.yml /etc/openstack_deploy/env.d/
echo 'done!'

if [[ $1 == '-e' ]] ; then
        echo 'Running HA proxy script'
        openstack-ansible playbook-metrics-lb.yml
        echo 'done!'
fi

echo 'Create containers'
openstack-ansible /opt/openstack-ansible/playbooks/lxc-containers-create.yml -e container_group=cluster-metrics
echo 'done!'

echo 'Install InfluxDB'
openstack-ansible playbook-influx-db.yml
echo 'done!'

echo 'Install Influx Telegraf'
openstack-ansible playbook-influx-telegraf.yml --forks 100
echo 'done!'

echo 'Install Grafana'
read GALERA_IP <<< $(lxc-ls -f | grep galera | awk '{ print $7 }')
openstack-ansible  playbook-grafana.yml -e galera_root_user=root -e galera_address=$GALERA_IP
echo 'done!'

echo 'Install kapacitor'
openstack-ansible playbook-kapacitor.yml
echo 'done!'
