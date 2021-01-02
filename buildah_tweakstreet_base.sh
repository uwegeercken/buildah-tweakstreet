#!/bin/bash
#
# script to create a OCI compliant image for the Tweakstreet ETL tool using buildah.
#
# the script prepares a base image which then can be used as a blueprint for other images. It pulls the version specified in "tweakstreet_version" from the Tweakstreet website.
# the program is available in the "/opt/tweakstreet" folder.
#

# base image
image_base=debian:buster-slim

# new image
image_name="tweakstreet-base"
image_version="0.1"
image_format="docker"
image_author="Tweakstreet Docker Maintainers <hi@tweakstreet.io>"

# image user
image_user="tweakstreet"
image_user_id=101
image_group="tweakstreet"
image_group_id=101

# tweakstreet application
tweakstreet_version="1.13.0"
tweakstreet_url="https://tweakstreet.io/updates"
tweakstreet_home="/home/tweakstreet"
tweakstreet_drivers="${tweakstreet_home}/.tweakstreet/drivers"
tweakstreet_location="/opt/tweakstreet"
tweakstreet_local_folder="Tweakstreet-${tweakstreet_version}-portable"

# tweakstreet folder for flows, modules, etc.
tweakstreet_flows="${tweakstreet_home}/flows"

# name of working container
working_container="${image_name}-working-container"

# start of build
echo "[INFO] start of build..."
container=$(buildah --name "${working_container}" from ${image_base})

# create group and user - also creates the home folder
buildah run $container addgroup --gid "${image_group_id}" "${image_group}" 
buildah run $container adduser --system --home "${tweakstreet_home}" --ingroup "${image_group}" --gecos "tweakstreet user" --shell /bin/bash --uid "${image_user_id}" "${image_user}"

# create folders
buildah run $container mkdir -p "${tweakstreet_drivers}"
buildah run $container mkdir -p "${tweakstreet_location}"
buildah run $container mkdir -p "${tweakstreet_flows}"

if [ ! -d "${tweakstreet_local_folder}" ]
then
	curl "${tweakstreet_url}/Tweakstreet-${tweakstreet_version}-portable.tar.gz" --output "${tweakstreet_local_folder}.tar.gz"
	tar -xzf ${tweakstreet_local_folder}.tar.gz
	rm ${tweakstreet_local_folder}.tar.gz
fi

# copy tweakstreet application files
buildah copy $container "${tweakstreet_local_folder}/" "${tweakstreet_location}"

# change ownership
buildah run $container chown -R "${image_user}":"${image_group}" "${tweakstreet_home}"
buildah run $container chown -R "${image_user}":"${image_group}" "${tweakstreet_location}"

# config
buildah config --env PATH="${tweakstreet_location}/bin:/bin:$PATH" $container
buildah config --author="${image_author}" $container
buildah config --user="${image_user}:${image_group}" $container

# commit container, create image
buildah commit --format "${image_format}" $container "${image_name}:${image_version}"

# remove container
buildah rm $container

