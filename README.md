dockup-postgres
============

[![Docker Hub Badge](https://img.shields.io/badge/Docker-Hub%20Hosted-blue.svg)](https://hub.docker.com/r/wetransform/dockup-postgres/)

This is based on [dockup-mongo](https://github.com/robbyoconnor/dockup-mongo) (which was based on [dockup-mongo](https://github.com/wetransform-os/dockup-mongo)) but for postgres.
Docker image to backup/restore your PostgreSQL DB to AWS S3.
Builds upon [dockup](https://github.com/wetransform-os/dockup).

Configuration
-------------

This Docker image uses `pg_dump` to create a PostgreSQL database dump and backup or restore it with [dockup](https://github.com/wetransform-os/dockup).
Please see the [dockup](https://github.com/wetransform-os/dockup) repository for extended information on configuration options, for instance on how to configure encryption with GnuPG.

The following PostgreSQL specific configuration options have been added:

* **POSTGRES_HOST** - the host/ip of your postgres database (defaults to `db`)
* **POSTGRES_PORT** - the port number of your postgres database (defaults to `5432`)
* **POSTGRES_USER** - the username of your postgres database. (defaults to `postgres`)
* **POSTGRES_PASS** - the password of your postgres database.
* **POSTGRES_DB** - the database name to dump. (defaults to `postgres`)
* **POSTGRES_DUMP_EXTRA_OPTS** - the extra options to pass to pg_dump command
* **POSTGRES_RESTORE_EXTRA_OPTS** - the extra options to pass to pg_restore command

Usually you will link your PostgreSQL container to the *dockup* container.

For an example runnning backup and restore, see the `./test-backup.sh` script.
Before running it, ensure there is a file `test-env.txt` with configuration options as in `test-env.txt.sample`.

The following *dockup* environment variables should **not be overriden** if using the specialised PostgreSQL (dockup-postgres) image:

* **BEFORE_BACKUP_CMD**
* **AFTER_BACKUP_CMD**
* **AFTER_RESTORE_CMD**
* **PATHS_TO_BACKUP**

### Example
This is what a postgres and backup service might look like in `docker-compose.yaml`.  Note the `dockup-postgres` specific variables in addition to others needed by [dockup](https://github.com/wetransform-os/dockup)
```
    backup:
      links:
        - postgres
      environment:
        - POSTGRES_PASS=passw0rd
        - POSTGRES_HOST=postgres
        - POSTGRES_DB=postgres
        - AWS_ACCESS_KEY_ID=aws_key_id
        - AWS_DEFAULT_REGION=us-east-1
        - AWS_SECRET_ACCESS_KEY=aws_secret_key
        - BACKUP_NAME=test
        - PATHS_TO_BACKUP=/dockup/pgdump
        - RESTORE=false
        - S3_BUCKET_NAME=test-name
        - S3_FOLDER=backups/
      image: dockup-postgres:latest
    postgres:
      environment:
        - POSTGRES_PASSWORD=passw0rd
      image: postgres:latest
      ports:
        - 5432:5432
      volumes:
        - /var/lib/postgresql/data

```
