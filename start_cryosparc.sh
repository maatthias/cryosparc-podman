#!/bin/bash

export PATH=${CRYOSPARC_MASTER_DIR}/bin:${CRYOSPARC_WORKER_DIR}/bin:${CRYOSPARC_MASTER_DIR}/deps/anaconda/bin/:$PATH
export HOME=${HOME:-$USER_HOMEDIR}
export LSCRATCH=${LSCRATCH:-/lscratch/$USER}
export CRYOSPARC_MASTER_HOSTNAME=${CRYOSPARC_MASTER_HOSTNAME:-localhost}

CRYOSPARC_BASE_PORT=${CRYOSPARC_BASE_PORT:-"39000"}
# export CRYOSPARC_SUPERVISOR_SOCK_FILE="${LSCRATCH}/cryosparc-supervisor.sock" 

echo "Starting cryosparc master..."
cd ${CRYOSPARC_MASTER_DIR}
# modify configuration
# printf "%s\n" "1,\$s/^export CRYOSPARC_MASTER_HOSTNAME=.*$/export CRYOSPARC_MASTER_HOSTNAME=${CRYOSPARC_MASTER_HOSTNAME}/g" wq | ed -s ${CRYOSPARC_MASTER_DIR}/config.sh
# printf "%s\n" "1,\$s/^export CRYOSPARC_LICENSE_ID=.*$/export CRYOSPARC_LICENSE_ID=${CRYOSPARC_LICENSE_ID}/g" wq | ed -s ${CRYOSPARC_MASTER_DIR}/config.sh
# printf "%s\n" "1,\$s|^export CRYOSPARC_DB_PATH=.*$|export CRYOSPARC_DB_PATH=${CRYOSPARC_DATADIR}/cryosparc_database|g" wq | ed -s ${CRYOSPARC_MASTER_DIR}/config.sh
# printf "%s\n" "1,\$s/^export CRYOSPARC_BASE_PORT=.*$/export CRYOSPARC_BASE_PORT=${CRYOSPARC_BASE_PORT}/g" wq | ed -s ${CRYOSPARC_MASTER_DIR}/config.sh
#printf "%s\n" "export CRYOSPARC_SUPERVISOR_SOCK_FILE=${CRYOSPARC_SUPERVISOR_SOCK_FILE}" wq | ed -s ${CRYOSPARC_MASTER_DIR}/config.sh
#printf "%s\n" "export CRYOSPARC_MONGO_EXTRA_FLAGS=\"  --unixSocketPrefix=${LSCRATCH}\"" wq | ed -s ${CRYOSPARC_MASTER_DIR}/config.sh
echo "export CRYOSPARC_SUPERVISOR_SOCK_FILE=${CRYOSPARC_SUPERVISOR_SOCK_FILE}" >> ${CRYOSPARC_MASTER_DIR}/config.sh
echo "export CRYOSPARC_MONGO_EXTRA_FLAGS=\"  --unixSocketPrefix=/tmp\"" >> ${CRYOSPARC_MASTER_DIR}/config.sh
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
# rm -f "${SOCK_FILE}" || true
rm -f "${CRYOSPARC_SUPERVISOR_SOCK_FILE}" || true

cryosparcm start database
cryosparcm fixdbport
cryosparcm restart
