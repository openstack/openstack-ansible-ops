#!/bin/bash

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

echo Unpacking tarball cluster-api-objects.tar.gz
tar -xvf cluster-api-objects.tar.gz -C $SCRIPT_DIR

# Separate out the secrets from the yaml files
mkdir $SCRIPT_DIR/secrets
mv $SCRIPT_DIR/cluster-api-backup/*.txt $SCRIPT_DIR/secrets/

echo Restoring Cluster API objects from yaml files in the backup
clusterctl move --from-directory $SCRIPT_DIR/cluster-api-backup/

# Iterate over .txt files for each cluster and recreate k8s secrets
while read clustername; do
  echo Creating secret ${clustername}-cloud-config
  kubectl create secret -n magnum-system generic ${clustername}-cloud-config --from-file=cacert=$SCRIPT_DIR/secrets/cacert-${clustername}.txt --from-file=clouds\.yaml=$SCRIPT_DIR/secrets/clouds-yaml-${clustername}.txt
done <$SCRIPT_DIR/secrets/cluster-names.txt

# Delete the secrets files
rm -rf $SCRIPT_DIR/secrets
