#!/bin/bash
#
# Simple test script for backup and restore
# 
# Before running it, ensure there is a file test-env.txt
# with configuration options as in test-env.txt.sample

# build dockup image
docker build -t wetransform/dockup-postgres:local .

POSTGRES_PASSWORD="postgres"
POSTGRES_USER="postgres"
POSTGRES_DB="postgres"

POSTGRES_IMAGE="postgres:9.6"

# run PostgreSQL/PostGIS
docker stop dockup-postgres-test
docker rm dockup-postgres-test
docker run -d --name dockup-postgres-test \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  $POSTGRES_IMAGE

# wait for PostgreSQL to be ready (TODO better way to wait?)
sleep 10

# create dummy content to backup
file_time=`date +%Y-%m-%d\\ %H:%M:%S\\ %Z`
docker exec dockup-postgres-test psql --username "$POSTGRES_USER" "$POSTGRES_DB" -c \
  "CREATE TABLE test_table (name VARCHAR, value VARCHAR); \
   INSERT INTO test_table (name, value) VALUES ('test1', '$file_time'); \
   INSERT INTO test_table (name, value) VALUES ('test2', 'fixed'); \
   SELECT * FROM test_table;"
rc=$?; if [ $rc -ne 0 ]; then
  echo "ERROR: Error creating dummy content for database"
  docker stop dockup-postgres-test
  docker rm dockup-postgres-test
  exit $rc
fi

# backup
docker run --rm \
  --env-file test-env.txt \
  --link dockup-postgres-test:postgresdb \
  -e BACKUP_NAME=dockup-postgres-test \
  -e POSTGRES_HOST=postgresdb \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASS=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  --name dockup-run-test wetransform/dockup-postgres:local
rc=$?; if [ $rc -ne 0 ]; then
  echo "ERROR: Error running backup"
  exit $rc
fi

# recreate PostgreSQL/PostGIS container
docker stop dockup-postgres-test
docker rm dockup-postgres-test
docker run -d --name dockup-postgres-test \
  -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
  $POSTGRES_IMAGE

# wait for PostgreSQL to be ready (TODO better way to wait?)
sleep 10

# restore
docker run --rm \
  --env-file test-env.txt \
  --link dockup-postgres-test:postgresdb \
  -e BACKUP_NAME=dockup-postgres-test \
  -e POSTGRES_HOST=postgresdb \
  -e POSTGRES_PORT=5432 \
  -e POSTGRES_USER=$POSTGRES_USER \
  -e POSTGRES_PASS=$POSTGRES_PASSWORD \
  -e POSTGRES_DB=$POSTGRES_DB \
  -e RESTORE=true \
  -e POSTGRES_RESTORE_EXTRA_OPTS=--no-data-for-failed-tables \
  --name dockup-run-test wetransform/dockup-postgres:local
rc=$?; if [ $rc -ne 0 ]; then
  echo "WARNING: Errors or warnings while running restore"
fi

RESULT=$(docker exec dockup-postgres-test psql --username "$POSTGRES_USER" -d "$POSTGRES_DB" -c 'SELECT * from test_table;')
echo "$RESULT"

docker stop dockup-postgres-test
docker rm dockup-postgres-test

# Output should be something like:
#
#  name  |          value          
# -------+-------------------------
#  test1 | 2019-03-01 16:21:16 CET
#  test2 | fixed
# (2 rows)

RESULT_ROWS=$(echo "$RESULT" | grep rows)

if [ "$RESULT_ROWS" != "(2 rows)" ]; then
  echo "ERROR: Backup did not restore all rows"
  exit $rc
else
  echo "Restored database table successfully"
fi

RESULT_FIXED=$(echo "$RESULT" | grep test2)

if [ "$RESULT_FIXED" != " test2 | fixed" ]; then
  echo "ERROR: Backup did not restore row with fixed content"
  exit $rc
else
  echo "Restored row with fixed content successfully"
fi

RESULT_VAR=$(echo "$RESULT" | grep test1)

if [ "$RESULT_VAR" != " test1 | $file_time" ]; then
  echo "ERROR: Backup did not restore row with variable content"
  exit $rc
else
  echo "Restored row with variable content successfully"
fi