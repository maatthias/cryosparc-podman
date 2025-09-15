#!/bin/bash

export PATH=${CRYOSPARC_MASTER_DIR}/bin:${CRYOSPARC_WORKER_DIR}/bin:${CRYOSPARC_MASTER_DIR}/deps/anaconda/bin/:$PATH
export HOME=${HOME:-$USER_HOMEDIR}
export LSCRATCH=${LSCRATCH:-/lscratch/$USER}
export CRYOSPARC_MASTER_HOSTNAME=${CRYOSPARC_MASTER_HOSTNAME:-localhost}

CRYOSPARC_BASE_PORT=${CRYOSPARC_BASE_PORT:-"39000"}
export CRYOSPARC_SUPERVISOR_SOCK_FILE="${LSCRATCH}/cryosparc-supervisor.sock" 
mkdir -p ${LSCRATCH}

echo "Starting cryosparc master..."
cd ${CRYOSPARC_MASTER_DIR}
# modify configuration
echo "export CRYOSPARC_SUPERVISOR_SOCK_FILE=${CRYOSPARC_SUPERVISOR_SOCK_FILE}" >> ${CRYOSPARC_MASTER_DIR}/config.sh
echo "export CRYOSPARC_MONGO_EXTRA_FLAGS=\"  --unixSocketPrefix=${LSCRATCH}\"" >> ${CRYOSPARC_MASTER_DIR}/config.sh
if ! grep -q 'CRYOSPARC_FORCE_HOSTNAME=true' ${CRYOSPARC_MASTER_DIR}/config.sh; then
  echo 'export CRYOSPARC_FORCE_HOSTNAME=true' >> ${CRYOSPARC_MASTER_DIR}/config.sh
fi
echo '====='
cat ${CRYOSPARC_MASTER_DIR}/config.sh
echo '====='

# envs
THIS_USER=$(whoami)
THIS_USER_SUFFIX=${USER_SUFFIX:-'bnl.gov'}
ACCOUNT="${THIS_USER}@${THIS_USER_SUFFIX}"
rm -f "${CRYOSPARC_SUPERVISOR_SOCK_FILE}" || true

cryosparcm start database
cryosparcm fixdbport
cryosparcm restart

cryosparcm createuser --email cryosparc@bnl.gov --password $CRYOSPARC_LICENSE_ID --username "cryosparc" --firstname "Cryo" --lastname "Sparc"

while true
do
	cryosparcm status
	sleep 5
done
