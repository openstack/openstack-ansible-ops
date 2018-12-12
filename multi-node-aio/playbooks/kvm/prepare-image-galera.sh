#!/bin/bash -ex

# clean up from any previous attempts
rm -rf /tmp/*galera* /tmp/gvw*

# provide default images to inspect
infra_images="/data/images/infra1.img /data/images/infra2.img /data/images/infra3.img"

# declare an array to map images to container names
declare -A image_map

# declare an array to map container names to uuid's
declare -A uuid_map

# at this stage, no galera container is the master
master_cnt=""

echo "Getting the list of galera container names."
for img in ${infra_images}; do
  image_map[${img}]="$(virt-ls --add ${img} --mount /dev/vmvg00/openstack00 / | grep galera_container)"
done

# get the gvwstate.dat files from the image and
# put it into a local folder using the same name
# as the container
for img in ${infra_images}; do
  mkdir -p /tmp/${image_map[$img]}
  echo "Copying *.dat from ${img} into /tmp/${image_map[$img]}/"
  guestfish --ro --add ${img} --mount /dev/vmvg00/openstack00 glob copy-out /${image_map[$img]}/*.dat /tmp/${image_map[$img]}/
done

# work through the existing gvwstate files
# there may be more than one, so we need to
# find the one holding the view_id
for cnt in $(ls -1 /tmp | grep galera_container); do
  # generate a new uuid for this container
  uuid_map[${cnt}]=$(uuidgen)

  # work through the existing files to see
  # if there is a master present
  gvwstate_path="/tmp/${cnt}/gvwstate.dat"
  if [[ -e ${gvwstate_path} ]]; then
    echo "Found ${gvwstate_path}, extracting my_uuid/view_id."
    my_uuid=$(awk '/^my_uuid:/ { print $2 }' ${gvwstate_path})
    view_id=$(awk '/^view_id:/ { print $3 }' ${gvwstate_path})

    # just in case there is no master found, we store the
    # last one we saw so that we can use it as a fallback
    echo "Setting last_gvwstate_path to ${gvwstate_path}."
    last_gvwstate_path=${gvwstate_path}

    if [[ "${my_uuid}" == "${view_id}" ]]; then
      echo "Found galera master in ${gvwstate_path}."
      master_gvwstate_path=${gvwstate_path}
      master_cnt=${cnt}
    fi
  else
    # if there is no gvwstate.dat file, then we will
    # need to use my_uuid later to generate one
    my_uuid=${uuid_map[$cnt]}
  fi

  # if a master container was found, overwrite the uuid
  # to the uuid from it
  if [[ "${cnt}" == "${master_cnt:-none}" ]]; then
    uuid_map[${cnt}]=${my_uuid}
  fi
done

echo "Prepare a new master gvwstate.dat in a temporary location."
tmp_gvwstate="/tmp/gvwstate.dat"
if [[ "${master_gvwstate_path:-none}" != "none" ]]; then
  cp ${master_gvwstate_path} ${tmp_gvwstate}
elif [[ "${last_gvwstate_path:-none}" != "none" ]]; then
  cp ${last_gvwstate_path} ${tmp_gvwstate}
else
  echo "No gvwstate.dat file was found. Attempting to put one together."
cat > ${tmp_gvwstate}<< EOF
my_uuid: ${my_uuid}
#vwbeg
view_id: 3 ${my_uuid} 3
bootstrap: 0
member: ${my_uuid} 0
#vwend
EOF
fi
member_num=$(awk '/^member: '${my_uuid}'/ {print $3}' ${tmp_gvwstate})

echo "Clearing the existing members."
sed -i.bak '/^member:/d' ${tmp_gvwstate}

echo "Inserting the new set of members."
for cnt_uuid in "${uuid_map[@]}"; do
sed -i.bak "/^#vwend$/i \\
member: ${cnt_uuid} ${member_num}" ${tmp_gvwstate}
done

echo "Copying the new gvwstate.dat version to each working location."
for cnt in "${!uuid_map[@]}"; do
  sed "s/my_uuid: .*/my_uuid: ${uuid_map[$cnt]}/" ${tmp_gvwstate} > /tmp/${cnt}/gvwstate.dat
done

echo "Putting the gvwstate.dat files back into the images."
for img in ${infra_images}; do
  echo "Copying /tmp/${image_map[$img]}/gvwstate.dat into ${img}."
  guestfish --rw --add ${img} --mount /dev/vmvg00/openstack00 copy-in /tmp/${image_map[$img]}/gvwstate.dat  /${image_map[$img]}/
done

echo "Image preparation completed."
