
The script creates an OCI compliant container base image (using buildah) for the Tweakstreet ETL tool. See https://tweakstreet.io/. The base image can then be used as a blueprint for other images.

The desired version of the ETL tool is specified in the variable "tweakstreet_version". It is downloaded at build time from the relevant URL and copied to the "/opt/tweakstreet" folder in the image. A folder "/home/tweakstreet/.tweakstreet/drivers is created. A user and group "tweakstreet" is created.

When creating an image from this base image, all required files - such as control-flows, data-flows, modules or data files - shall be copied to a folder in the image; e.g. "/home/tweakstreet/flows". All required JDBC drivers must be copied to the folder "/home/tweakstreet/.tweakstreet/drivers". A flow can then be run specifying the engine.sh script and the flow to run.

Example:

	podman run -it --rm <îmage> engine.sh /home/tweakstreet/flows/myflow.dfl

	or
	
	docker run -it --rm <îmage> engine.sh /home/tweakstreet/flows/myflow.dfl

The resulting image can then be pushed to a registry.

last update: uwe.geercken@web.de - 2021-10-17

