FROM postgres:10

ARG identifier

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates wget python-pip curl build-essential

# https://www.2ndquadrant.com/en/resources/pglogical/pglogical-installation-instructions/
RUN echo "deb [arch=amd64] http://packages.2ndquadrant.com/pglogical/apt/ jessie-2ndquadrant main\n" \
    > /etc/apt/sources.list.d/2ndquadrant.list
RUN wget --quiet -O - http://packages.2ndquadrant.com/pglogical/apt/AA7A6805.asc | apt-key add - && apt-get update
RUN apt-get install -y --no-install-recommends postgresql-server-dev-10 libpq-dev
RUN apt-get install -y --no-install-recommends postgresql-10-pglogical

# Make 'wait' script available
ADD https://raw.githubusercontent.com/eficode/wait-for/master/wait-for /usr/local/bin/waitfor
RUN chmod +x /usr/local/bin/waitfor

# Copy custom postgres conf to container
ADD pgdata /tmp/pgdata
COPY customconfig.sh /docker-entrypoint-initdb.d/_customconfig.sh

# Entrypoint for this proof of concept
COPY entrypoint.sh /usr/local/bin
RUN chmod +x /usr/local/bin/entrypoint.sh

# Add setup script for given node - nodes and subscribers are created in these scripts
ADD nodes/${identifier}/*.sh /tmp
RUN chmod +x /tmp/setup.sh
