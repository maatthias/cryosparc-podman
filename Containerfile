# FROM nvidia/cuda:12.8.1-devel-rockylinux9
FROM rockylinux:9

RUN dnf -y upgrade \
  && dnf install -y epel-release dnf-plugins-core \
  && dnf config-manager --enable crb \
  && dnf install -y \
    iputils \
    jq \
    libtiff \
    munge \
    net-tools \
    openssh-server \
    python3 \
    python3-devel \
    python3-pip \
    sudo \
    which \
    zip unzip \
  && dnf clean all

ENV CRYOSPARC_ROOT_DIR=/app
RUN mkdir -p ${CRYOSPARC_ROOT_DIR}
WORKDIR ${CRYOSPARC_ROOT_DIR}

ARG CRYOSPARC_LICENSE_ID
ENV CRYOSPARC_LICENSE_ID=${CRYOSPARC_LICENSE_ID}

# download
RUN curl -L https://get.cryosparc.com/download/master-latest/${CRYOSPARC_LICENSE_ID} -o cryosparc_master.tar.gz
RUN tar -xzf cryosparc_master.tar.gz
RUN curl -L https://get.cryosparc.com/download/worker-latest/${CRYOSPARC_LICENSE_ID} -o cryosparc_worker.tar.gz
RUN tar -xzf cryosparc_worker.tar.gz

ENV CRYOSPARC_MASTER_DIR=${CRYOSPARC_ROOT_DIR}/cryosparc_master
WORKDIR ${CRYOSPARC_MASTER_DIR}

# cryosparc installation needs non-root user
ENV USER=cryosparc
# allow any user to start service
RUN sed -i '/^echo "# Other" >> config.sh$/a echo \"export CRYOSPARC_FORCE_USER=true\" >> config.sh' ./install.sh
# make sure cryosparc uses explicit container name not the one generated by build
RUN sed -i '/^echo "# Other" >> config.sh$/a echo \"export CRYOSPARC_HOSTNAME_CHECK=localhost\" >> config.sh' ./install.sh
ENV CRYOSPARC_MASTER_HOSTNAME=localhost

RUN cat install.sh
RUN env | sort

RUN ./install.sh \
    --yes \
    --license $CRYOSPARC_LICENSE_ID \
    --standalone \
    --allowroot \
    --insecure \
    --nossd \
    --disable_db_auth \
    --hostname "localhost" \
    --worker_path ${CRYOSPARC_ROOT_DIR}/cryosparc_worker \
    # --ssdpath /scratch/cryosparc_cache \
    --initial_email "cryosparc@bnl.gov" \
    --initial_password $CRYOSPARC_LICENSE_ID \
    --initial_username "cryosparc" \
    --initial_firstname "Cryo" \
    --initial_lastname "Sparc" \
    --port 39000

# inspect
RUN ls -al /tmp/
RUN cat config.sh
# RUN ps aux | grep -i cryosparc
RUN env | sort

COPY start_cryosparc.sh /start_cryosparc.sh
RUN chmod 0755 /start_cryosparc.sh

EXPOSE 39000 39001 39002 39003 39004 39006

ENV PATH=$PATH:${CRYOSPARC_MASTER_DIR}/bin

# make socket file deterministic
RUN root_dir_hash=$(echo -n $CRYOSPARC_ROOT_DIR | md5sum | awk '{print $1}')
RUN export CRYOSPARC_SUPERVISOR_SOCK_FILE=/tmp/cryosparc-supervisor-${root_dir_hash}.sock

# make mount points for workshop data and workspaces
RUN mkdir -p /nsls2/data/cryoem/workshop
RUN mkdir -p /nsls2/data/cryoem/legacy/temp_workshop2025_1

ENTRYPOINT ["/start_cryosparc.sh"]
# CMD ["cryosparcm", "start"]
