FROM debian:stretch-slim

# Set environment variables.
ENV LANG=en_US.utf8
ENV GOSU_VERSION=1.11
ENV PG_MAJOR=9.4
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/9.4/bin
ENV PGDATA=/var/lib/postgresql/data

# Set up locale
RUN set -eux; if [ -f /etc/dpkg/dpkg.cfg.d/docker ]; then grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; sed -ri '/\/usr\/share\/locale/d' /etc/dpkg/dpkg.cfg.d/docker; ! grep -q '/usr/share/locale' /etc/dpkg/dpkg.cfg.d/docker; fi; apt-get update; apt-get install -y locales; rm -rf /var/lib/apt/lists/*; localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

# Create postgres user and group and set up /var/lib/postgresql directory.
RUN groupadd -r postgres --gid=999; useradd -r -g postgres --uid=999 --home-dir=/var/lib/postgresql --shell=/bin/bash postgres
RUN mkdir -p /var/lib/postgresql
RUN chown -R postgres:postgres /var/lib/postgresql

# Install dependencies
RUN apt-get update
RUN apt-get install -y --no-install-recommends gnupg dirmngr libnss-wrapper curl lsb-release apt-transport-https ca-certificates wget

# Install gosu
RUN set -x  \
	&& wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/$GOSU_VERSION/gosu-$(dpkg --print-architecture)"  \
	&& chmod +x /usr/local/bin/gosu  \
	&& gosu nobody true

# Add postgres apt repo.
RUN echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list && \
  curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add -

# Add BDR apt repo.
RUN echo "deb https://apt.2ndquadrant.com/ $(lsb_release -cs)-2ndquadrant main" > /etc/apt/sources.list.d/2ndquadrant.list && \
  curl https://apt.2ndquadrant.com/site/keys/9904CD4BD6BAF0C3.asc | apt-key add -

RUN apt-get update

# Install postgres
RUN apt-get install -y postgresql-common "postgresql-$PG_MAJOR" "postgresql-contrib-$PG_MAJOR"

# Install BDR.
RUN apt-get install -y postgresql-bdr-9.4-bdr-plugin

# Create pid file directory and set up permissions.
RUN mkdir -p /var/run/postgresql  \
	&& chown -R postgres:postgres /var/run/postgresql  \
	&& chmod 2777 /var/run/postgresql

# Set up PGDATA directory.
RUN mkdir -p "$PGDATA"  \
	&& chown -R postgres:postgres "$PGDATA"  \
	&& chmod 777 "$PGDATA"

# Create PGDATA volume by default.
VOLUME [ /var/lib/postgresql/data ]

# Copy entrypoint and config files.
COPY docker-entrypoint.sh /
COPY postgresql.conf /
COPY pg_hba.conf /

# Set entrypoint as executable.
RUN chmod +x /docker-entrypoint.sh

ENTRYPOINT ["/docker-entrypoint.sh"]

# Expose default port
EXPOSE 5432

CMD ["postgres"]
