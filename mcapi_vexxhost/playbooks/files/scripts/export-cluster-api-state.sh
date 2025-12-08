#!/bin/bash

MKTEMP=$(mktemp -d)
TEMPDEST=$MKTEMP/cluster-api-backup
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

# ensure data is not readable inside working directory
mkdir --mode 0600 $TEMPDEST
umask 0037

# Try several times if necessary to export objects as this may fail if any cluster is changing state (e.g. being provisioned)
for retry in {1..20}; do
  clusterctl move --to-directory $TEMPDEST --namespace magnum-system && break
  sleep 30
done

# Output list of workload cluster names, such as "kube-abc12"
CLUSTER_NAMES=$(kubectl get clusters -n magnum-system --no-headers -o custom-columns=:metadata.name)
echo "$CLUSTER_NAMES" > $TEMPDEST/cluster-names.txt

# Export cloud-config secrets from each cluster in turn
for cluster in $CLUSTER_NAMES; do
  echo Exporting ${cluster}-cloud-config
  kubectl get secret -n magnum-system ${cluster}-cloud-config  -o jsonpath='{.data.cacert}' | base64 --decode > $TEMPDEST/cacert-${cluster}.txt
  kubectl get secret -n magnum-system ${cluster}-cloud-config  -o jsonpath='{.data.clouds\.yaml}' | base64 --decode > $TEMPDEST/clouds-yaml-${cluster}.txt
done

tar -czvf $SCRIPT_DIR/cluster-api-objects.tar.gz -C $MKTEMP cluster-api-backup
chmod g+r $SCRIPT_DIR/cluster-api-objects.tar.gz

echo Cluster API objects saved in $SCRIPT_DIR

# Make sure the temp directory gets removed on script exit.
trap "exit 1"           HUP INT PIPE QUIT TERM
trap 'rm -rf "$MKTEMP"' EXIT
