FROM wetransform/dockup:latest
MAINTAINER Simon Templer <simon@wetransform.to>

# add build info - see hooks/build and https://github.com/opencontainers/image-spec/blob/master/annotations.md
ARG BUILD_DATE
ARG VCS_REF
ARG VCS_URL
LABEL org.opencontainers.image.created=$BUILD_DATE \
  org.opencontainers.image.source=$VCS_URL \
  org.opencontainers.image.revision=$VCS_REF


# install Postgres shell & tools
ENV PG_MAJOR 9.6
RUN echo 'deb http://apt.postgresql.org/pub/repos/apt/ jessie-pgdg main' $PG_MAJOR > /etc/apt/sources.list.d/pgdg.list
RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8
RUN apt-get update && apt-get install -y \
    postgresql-client-$PG_MAJOR

ENV PATHS_TO_BACKUP /dockup/pgdump
VOLUME ["/dockup/pgdump"]
ENV POSTGRES_BACKUP_NAME pgdump
ENV BEFORE_BACKUP_CMD ./pgdump.sh
ENV AFTER_BACKUP_CMD ./pgclean.sh
ENV AFTER_RESTORE_CMD ./pgrestore.sh
ENV POSTGRES_USER postgres
ENV POSTGRES_HOST db
ENV POSTGRES_DB postgres
ENV POSTGRES_PORT 5432
COPY /scripts /dockup/
RUN chmod 755 /dockup/*.sh

