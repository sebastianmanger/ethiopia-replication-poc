#!/bin/sh

# Call the entrypoint of the postgresql container, starting postgres.
docker-entrypoint.sh postgres &
waitfor localhost:5432 -- echo "Postgres is up"

# For all datacentres / containers: preparations (see: poc.md # preparations)
echo "Create extension, database and users"
psql -U postgres -c "DROP DATABASE IF EXISTS test;"
psql -U postgres -c "CREATE DATABASE test;"
psql -U postgres -d test -c "CREATE EXTENSION IF NOT EXISTS pglogical;"
psql -U postgres -d test -c "DROP ROLE IF EXISTS replication;"
psql -U postgres -d test -c "CREATE ROLE replication WITH SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD '1234';"

# Setup this node
./tmp/setup.sh
exec "$@"
