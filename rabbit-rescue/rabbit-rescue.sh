#!/usr/bin/env bash
#
# Copyright 2020 Henry Bonath <henry@thebonaths.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# **Use this script at your own risk - we do our best to not do any damage but YMMV!**


# All Services - populate this array with the names of the services you are running in your cluster
# some defaults are provided below
all_services=( cinder nova neutron heat glance ceilometer )

# Rabbit Secrets - populate the vars below with information found in /etc/openstack_deploy/user_secrets.yml
# These will be used when re-creating the vhosts and *must* be named based on the service names above
cinder_oslomsg_rpc_password=MYSECRETcinderPassw0rd
nova_oslomsg_rpc_password=MYSECRETnovaPassw0rd
neutron_oslomsg_rpc_password=MYSECRETneutronPassw0rd
heat_oslomsg_rpc_password=MYSECRETheatPassw0rd
glance_oslomsg_rpc_password=MYSECRETglancePassw0rd
ceilometer_oslomsg_rpc_password=MYSECRETceilopmeterPassw0rd


for service in "${all_services[@]}"; do

  if ($(rabbitmqctl list_vhosts | grep "/$service" > /dev/null)); then
    echo "/$service vhost already exists, skipping."
  else
    echo "Creating /$service vhost:"
    rabbitmqctl add_vhost /$service
  fi

  if ($(rabbitmqctl list_users | grep "$service" > /dev/null)); then
    echo "$service user already exists, skipping."
  else
    echo "Creating $service user:"
    secret=$(printf \$"$service"_oslomsg_rpc_password)
    eval $(echo rabbitmqctl add_user $service $secret)
  fi

  if ($(rabbitmqctl list_permissions --vhost /$service | grep 'does not exist' > /dev/null)); then
    echo "Setting $service permissions:"
    rabbitmqctl set_permissions $service -p /$service ".*" ".*" ".*"
  else
    echo "$service permissions already set, skipping."
  fi

done


exit 0
