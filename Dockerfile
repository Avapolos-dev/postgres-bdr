FROM debian:stretch-slim

# Set environment variables.
ENV LANG=en_US.utf8
ENV GOSU_VERSION=1.11
ENV PG_MAJOR=9.4
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/lib/postgresql/9.4/bin
ENV PGDATA=/var/lib/postgresql/data

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

# Add postgres apt repo GPG keys.
RUN set -ex; key='B97B0AFCAA1A47F044F244A07FCC7D46ACCC4CF8'; export GNUPGHOME="$(mktemp -d)"; gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$key"; gpg --batch --export "$key" > /etc/apt/trusted.gpg.d/postgres.gpg; command -v gpgconf > /dev/null  \
	&& gpgconf --kill all; rm -rf "$GNUPGHOME"; apt-key list

# Install postgres
RUN set -ex; export PYTHONDONTWRITEBYTECODE=1; dpkgArch="$(dpkg --print-architecture)"; case "$dpkgArch" in amd64|i386|ppc64el) echo "deb http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list; apt-get update; ;; *) echo "deb-src http://apt.postgresql.org/pub/repos/apt/ stretch-pgdg main $PG_MAJOR" > /etc/apt/sources.list.d/pgdg.list; case "$PG_MAJOR" in 9.* | 10 ) ;; *) echo 'deb http://deb.debian.org/debian stretch-backports main' >> /etc/apt/sources.list.d/pgdg.list; ;; esac; tempDir="$(mktemp -d)"; cd "$tempDir"; savedAptMark="$(apt-mark showmanual)"; apt-get update; apt-get build-dep -y postgresql-common pgdg-keyring "postgresql-$PG_MAJOR" ; DEB_BUILD_OPTIONS="nocheck parallel=$(nproc)" apt-get source --compile postgresql-common pgdg-keyring "postgresql-$PG_MAJOR" ; apt-mark showmanual | xargs apt-mark auto > /dev/null; apt-mark manual $savedAptMark; ls -lAFh; dpkg-scanpackages . > Packages; grep '^Package: ' Packages; echo "deb [ trusted=yes ] file://$tempDir ./" > /etc/apt/sources.list.d/temp.list; apt-get -o Acquire::GzipIndexes=false update; ;; esac; apt-get install -y postgresql-common; sed -ri 's/#(create_main_cluster) .*$/\1 = false/' /etc/postgresql-common/createcluster.conf; apt-get install -y "postgresql-$PG_MAJOR" "postgresql-contrib-$PG_MAJOR" ; rm -rf /var/lib/apt/lists/*; if [ -n "$tempDir" ]; then apt-get purge -y --auto-remove; rm -rf "$tempDir" /etc/apt/sources.list.d/temp.list; fi; find /usr -name '*.pyc' -type f -exec bash -c 'for pyc; do dpkg -S "$pyc" &> /dev/null || rm -vf "$pyc"; done' -- '{}' +

# Add BDR apt repo and GPG keys.
RUN sh -c 'echo "deb https://apt.2ndquadrant.com/ $(lsb_release -cs)-2ndquadrant main" > /etc/apt/sources.list.d/2ndquadrant.list'
RUN curl https://apt.2ndquadrant.com/site/keys/9904CD4BD6BAF0C3.asc | apt-key add -

# Install BDR.
RUN apt-get update; apt-get install postgresql-bdr-9.4-bdr-plugin -y

# Update package cache
RUN apt-get update

RUN set -eux; dpkg-divert --add --rename --divert "/usr/share/postgresql/postgresql.conf.sample.dpkg" "/usr/share/postgresql/$PG_MAJOR/postgresql.conf.sample"; cp -v /usr/share/postgresql/postgresql.conf.sample.dpkg /usr/share/postgresql/postgresql.conf.sample; ln -sv ../postgresql.conf.sample "/usr/share/postgresql/$PG_MAJOR/"; sed -ri "s!^#?(listen_addresses)\s*=\s*\S+.*!\1 = '*'!" /usr/share/postgresql/postgresql.conf.sample; grep -F "listen_addresses = '*'" /usr/share/postgresql/postgresql.conf.sample

# Create pid file directory and set up permissions.
RUN mkdir -p /var/run/postgresql  \
	&& chown -R postgres:postgres /var/run/postgresql  \
	&& chmod 2777 /var/run/postgresql

# Set up PGDATA directory.
RUN mkdir -p "$PGDATA"  \
	&& chown -R postgres:postgres "$PGDATA"  \
	&& chmod 777 "$PGDATA" # this 777 will be replaced by 700 at runtime (allows semi-arbitrary "--user" values)

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
