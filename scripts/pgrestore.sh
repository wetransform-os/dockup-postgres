#!/bin/bash

source /dockup/pgconfig.sh

mkdir ${WORK_DIR}/pgdump || true

POSTGRES_RESTORE_CMD="/usr/bin/pg_restore -U ${POSTGRES_USER} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DB} ${POSTGRES_RESTORE_EXTRA_OPTS} ${WORK_DIR}/pgdump/${POSTGRES_BACKUP_NAME}"

echo "Restoring Postgres database dump..."
eval "time $POSTGRES_RESTORE_CMD"
rc=$?
/dockup/pgclean.sh

if [ $rc -ne 0 ]; then
  echo "ERROR: Failed to restore Postgres dump"
  exit $rc
else
  echo "Successfully restored database dump"
fi
