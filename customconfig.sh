#!/usr/bin/env bash

# Custom postgresql config. This is loaded at container start, but mainly done in this matter
# so the required changes are clearly visible in the /pgdata folder.

# Append additional config
cat /tmp/pgdata/postgresql.conf >> /var/lib/postgresql/data/postgresql.conf

# Replace full config!
cat /tmp/pgdata/pg_hba.conf > /var/lib/postgresql/data/pg_hba.conf
