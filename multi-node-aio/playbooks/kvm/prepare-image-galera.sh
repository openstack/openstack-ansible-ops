#!/bin/bash -ex

# provide default images to inspect
infra_images="/data/images/infra1.img /data/images/infra2.img /data/images/infra3.img"

# declare an array to map images to container names
declare -A image_map

# declare an array to map container names to uuid's
declare -A uuid_map

# at this stage, no galera container is the master
master_cnt=""

# get the list of galera container names
for img in ${infra_images}; do
  image_map[${img}]="$(virt-ls --add ${img} --mount /dev/vmvg00/openstack00 / | grep galera_container)"
done

# get the gvwstate.dat files from the image and
# put it into a local folder using the same name
# as the container
for img in ${infra_images}; do
  mkdir -p /tmp/${image_map[$img]}
  guestfish --ro --add ${img} --mount /dev/vmvg00/openstack00 glob copy-out /${image_map[$img]}/*.dat /tmp/${image_map[$img]}/
done

# work through the existing gvwstate files
# there may be more than one, so we need to
# find the one holding the view_id
for cnt in $(ls -1 /tmp | grep galera_container); do
  gvwstate_path="/tmp/${cnt}/gvwstate.dat"
  if [[ -e ${gvwstate_path} ]]; then
    my_uuid=$(awk '/^my_uuid:/ { print $2 }' ${gvwstate_path})
    view_id=$(awk '/^view_id:/ { print $3 }' ${gvwstate_path})
    if [[ "${my_uuid}" == "${view_id}" ]]; then
      master_gvwstate_path=${gvwstate_path}
      master_cnt=${cnt}
    fi
  fi
  if [[ "${cnt}" == "${master_cnt}" ]]; then
    uuid_map[${cnt}]=${my_uuid}
  else
    uuid_map[${cnt}]=$(uuidgen)
  fi
done

# prepare a new master in a temporary location
tmp_gvwstate="/tmp/gvwstate.dat"
cp ${master_gvwstate_path} ${tmp_gvwstate}
member_num=$(awk '/^member: '${my_uuid}'/ {print $3}' ${tmp_gvwstate})

# clear the existing members
sed -i.bak '/^member:/d' ${tmp_gvwstate}

# insert the new set of members
for cnt_uuid in "${uuid_map[@]}"; do
sed -i.bak "/^#vwend$/i \\
member: ${cnt_uuid} ${member_num}" ${tmp_gvwstate}
done

# copy the new version to each location
for cnt in "${!uuid_map[@]}"; do
  sed "s/my_uuid: .*/my_uuid: ${uuid_map[$cnt]}/" ${tmp_gvwstate} > /tmp/${cnt}/gvwstate.dat
done

# put the gvwstate.dat files back into the image
for img in ${infra_images}; do
  guestfish --rw --add ${img} --mount /dev/vmvg00/openstack00 copy-in /tmp/${image_map[$img]}/gvwstate.dat  /${image_map[$img]}/
done
