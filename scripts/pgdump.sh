#!/bin/bash

source /dockup/pgconfig.sh

mkdir ${WORK_DIR}/pgdump || true

POSTGRES_BACKUP_CMD="/usr/bin/pg_dump -Fc -U ${POSTGRES_USER} -h ${POSTGRES_HOST} -p ${POSTGRES_PORT} -d ${POSTGRES_DB} ${POSTGRES_DUMP_EXTRA_OPTS} -f ${WORK_DIR}/pgdump/${POSTGRES_BACKUP_NAME}"

echo "Creating Postgres database dump..."
eval "time $POSTGRES_BACKUP_CMD"
rc=$?
if [ $rc -ne 0 ]; then
  echo "ERROR: Failed to create Postgres dump"
  exit $rc
else
  echo "Successfully created database dump"
fi
