#!/bin/bash
#
# Script to create a OCI compliant image for the Tweakstreet ETL tool using buildah.
#
# The script prepares a base image which then can be used as a blueprint for other images. It pulls the version specified in "tweakstreet_version" from the Tweakstreet website. An image using this blueprint can copy all required flows, modules and data files to the /home/tweakstreet/flows folder
#
# A user "tweakstreet" with UID=101 and GID=101, which owns the programs files and the /home/tweakstreet folder and files is created.
#
# Following folders are available:
# - the Tweakstreet ETL tool root folder: /opt/tweakstreet
# - folder for JDBC drivers: /home/tweakstreet/.tweakstreet/drivers
# - folder for dataflows, control flows, modules, etc: /home/tweakstreet/flows
#
# The /opt/tweakstreet/bin folder where the shell script to run flows - engine.sh - is located, is available on the path.
#
# last update: uwe.geercken@web.de - 2022-01-05
#

# base image
image_base=debian:buster-slim

# new image
image_name="tweakstreet-base"
image_version="0.3"
image_format="docker"
image_author="Tweakstreet Image Maintainers <hi@tweakstreet.io>"

# image user
image_user="tweakstreet"
image_user_id=101
image_user_home="/home/tweakstreet"
image_group="tweakstreet"
image_group_id=101

# tweakstreet application
tweakstreet_version="1.19.4"
tweakstreet_download_url="https://updates.tweakstreet.io/updates"
tweakstreet_folder="/opt/tweakstreet"
tweakstreet_download_folder="Tweakstreet-${tweakstreet_version}-portable"

# tweakstreet folder for flows, modules, etc.
tweakstreet_flows_folder="${image_user_home}/flows"

# tweakstreet folder for data
tweakstreet_data_folder="${image_user_home}/data"

# tweakstreet folder for jdbc drivers
tweakstreet_drivers_folder="${image_user_home}/.tweakstreet/drivers"

# name of working container
working_container="${image_name}-working-container"

# start of build

# create the working container
container=$(buildah --name "${working_container}" from ${image_base})

# create group and user - also creates the home folder
buildah run $container addgroup --gid "${image_group_id}" "${image_group}"
buildah run $container adduser --system --home "${image_user_home}" --ingroup "${image_group}" --gecos "tweakstreet user" --shell /bin/bash --uid "${image_user_id}" "${image_user}"

# create folders
buildah run $container mkdir -p "${tweakstreet_folder}"
buildah run $container mkdir -p "${tweakstreet_drivers_folder}"
buildah run $container mkdir -p "${tweakstreet_flows_folder}"
buildah run $container mkdir -p "${tweakstreet_data_folder}"

# if the Tweakstreet application download for the selected version is not present, download it
if [ ! -f "${tweakstreet_download_folder}.tar.gz" ]
then
	curl "${tweakstreet_download_url}/Tweakstreet-${tweakstreet_version}-portable.tar.gz" --output "${tweakstreet_download_folder}.tar.gz"
fi

# untar the Tweakstreet ETL tool archive file - but only the "bin" folder and its content
tar -xz --wildcards -f ${tweakstreet_download_folder}.tar.gz "${tweakstreet_download_folder}/bin"

# copy tweakstreet application files
buildah copy $container "${tweakstreet_download_folder}/" "${tweakstreet_folder}"

# change ownership
buildah run $container chown -R "${image_user}":"${image_group}" "${image_user_home}"
buildah run $container chown -R "${image_user}":"${image_group}" "${tweakstreet_folder}"

# config
buildah config --env PATH="${tweakstreet_folder}/bin:/bin:$PATH" $container
buildah config --author="${image_author}" $container
buildah config --user="${image_user}:${image_group}" $container
buildah config --workingdir "${tweakstreet_flows_folder}" $container

# commit container, create image
buildah commit --format "${image_format}" $container "${image_name}:${image_version}"

# remove working container
buildah rm $container

# remove the Tweakstreet ETL tool local folder
if [ ! -z ${tweakstreet_download_folder+x} ]
then
	rm -rf ${tweakstreet_download_folder}
fi
