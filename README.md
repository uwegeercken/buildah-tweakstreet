
The script creates an OCI compliant container base image for the Tweakstreet ETL tool. See https://tweakstreet.io/. The base image can then be used as a blueprint for other images.

The desired version of the ETL tool is specified in the variable "tweakstreet_version". It is downloaded from the relevant URL and copied to the "/opt/tweakstreet" folder in the image. A folder "/home/tweakstreet/.tweakstreet/drivers is created. A user and group "tweakstreet" is created.


last update: uwe.geercken@web.de - 2021-01-02

