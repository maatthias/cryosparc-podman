# build cryosparc installation with podman
-----
forked/adopted from https://github.com/slaclab/cryosparc-docker
to work with rockylinux9 and podman
-----
## install/configure nvidia container toolkit to allow container access to nvidia drivers
### for rhel 9
- first set env var CRYOSPARC_LICENSE_ID={your_license_id}
- [nvidia container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
```sh
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | \
  tee /etc/yum.repos.d/nvidia-container-toolkit.repo
dnf install nvidia-container-toolkit
```
- [CDI for podman support](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/cdi-support.html)
```sh
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
nvidia-ctk cdi list

# verify with
podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable rockylinux:9 nvidia-smi --query-gpu=gpu_name,driver_version --format=csv,noheader
podman run --rm --device nvidia.com/gpu=all --security-opt=label=disable rockylinux:9 nvidia-smi -L
```

### for rhel 8
#### host preparation
- if above verification steps fail in rhel 8 you may need to do some extra steps 
- first set env var CRYOSPARC_LICENSE_ID={your_license_id}
- rhel8 requires container runtime hook
- [redhat article on using rhel 8 to do this with container runtime hook](https://www.redhat.com/en/blog/how-use-gpus-containers-bare-metal-rhel-8) but the basic steps distilled below
```sh
# check there are no nouveau drivers
lsmod | grep -i nouveau
# and remove if so
modprobe -r nouveau

# get and install cuda drivers
yum -y install http://developer.download.nvidia.com/compute/cuda/repos/rhel8/x86_64/cuda-repo-rhel8-10.2.89-1.x86_64.rpm
yum -y install cuda

# official nvidia cuda toolkit instructions
wget https://developer.download.nvidia.com/compute/cuda/12.8.1/local_installers/cuda-repo-rhel8-12-8-local-12.8.1_570.124.06-1.x86_64.rpm
rpm -i cuda-repo-rhel8-12-8-local-12.8.1_570.124.06-1.x86_64.rpm
dnf clean all
dnf -y install cuda-toolkit-12-8
# nvidia driver instructions (open flavor)
dnf -y module install nvidia-driver:open-dkms

# Load the NVIDIA and the unified memory kernel modules.
nvidia-modprobe && nvidia-modprobe -u

```

## build image
### master
```sh
podman image build --tag cryosparc-rockylinux9:latest --build-arg CRYOSPARC_LICENSE_ID=$CRYOSPARC_LICENSE_ID --file master/Containerfile_master

podman run --detach -e CRYOSPARC_LICENSE_ID=$CRYOSPARC_LICENSE_ID --name cryosparc --hostname cryosparc -p 39000:39000 -p 39001:39001 -p 39002:39002 -p 39003:39003 -p 39004:39004 -p 39005:39005 -p 39006:39006 localhost/cryosparc-rockylinux9

podman logs -f cryosparc




# podman image build --device nvidia.com/gpu=all --security-opt=label=disable --file Containerfile --tag cryosparc-rockylinux9:latest --build-arg CRYOSPARC_LICENSE_ID=$CRYOSPARC_LICENSE_ID --network=host
# # overlay
# podman run --detach --device nvidia.com/gpu=all --security-opt=label=disable --privileged -e CRYOSPARC_LICENSE_ID=${CRYOSPARC_LICENSE_ID} --name cryosparc --hostname cryosparc -p 39000:39000 -p 39001:39001 -p 39002:39002 -p 39003:39003 -p 39004:39004 localhost/cryosparc-rockylinux9
# # mounts
# podman run --detach --device nvidia.com/gpu=all --security-opt=label=disable --privileged -e CRYOSPARC_LICENSE_ID=${CRYOSPARC_LICENSE_ID} --name cryosparc --hostname cryosparc -p 39000:39000 -p 39001:39001 -p 39002:39002 -p 39003:39003 -p 39004:39004 -v /tmp/mongodb/db:/var/lib/mongo/db -v /tmp/cryosparc/u:/u -v /tmp/cryosparc/exp:/exp localhost/cryosparc-rockylinux9
```

## todos:
- use cryosparc user to install/run
```sh
adquery user cryosparc01
cryosparc01:x:406223:406223: , , , 26455:/nsls2/users/cryosparc01:/bin/false
```
- fix implicit dependency on `/etc/cdi/nvidia.yaml`
```sh
WARN[0000] Implicit hook directories are deprecated; set --hooks-dir="/usr/share/containers/oci/hooks.d" explicitly to continue to load ociHooks from this directory 
WARN[0000] Implicit hook directories are deprecated; set --hooks-dir="/etc/containers/oci/hooks.d" explicitly to continue to load ociHooks from this directory 
```
