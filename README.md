# build cryosparc installation with podman
-----
forked/adopted from https://github.com/slaclab/cryosparc-docker
to work with rockylinux9 and podman
-----

## build image
### master

```sh
export CRYOSPARC_LICENSE_ID=<your license>

podman image build --tag cryosparc-rockylinux9:latest --build-arg CRYOSPARC_LICENSE_ID=$CRYOSPARC_LICENSE_ID --squash --file Containerfile 

podman run --detach -e CRYOSPARC_LICENSE_ID=$CRYOSPARC_LICENSE_ID --name cryosparc --hostname cryosparc -p 39000:39000 -p 39001:39001 -p 39002:39002 -p 39003:39003 -p 39004:39004 -p 39005:39005 -p 39006:39006 localhost/cryosparc-rockylinux9

podman logs -f cryosparc
```