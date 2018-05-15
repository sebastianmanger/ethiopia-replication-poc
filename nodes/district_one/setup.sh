#!/bin/sh

# Setup this 'node'
psql -U postgres -d test -c "SELECT pglogical.drop_node('district_one', true)"
psql -U postgres -d test -c "SELECT pglogical.create_node(
    node_name := 'district_one',
    dsn := 'host=district_one port=5432 dbname=test user=replication'
);"

# Create a dummy table and ond some data - which will be synchronized.
psql -U postgres -d test -c "CREATE TABLE slm (
    uuid    integer primary key,
    name    varchar(40)
);"
# This is the data that is 'replicated' to all nodes that have a subscription to this node.
psql -U postgres -d test -c "INSERT INTO slm values (1, 'some name');"


# Provide data for 'subscribers' (in this case: region_one)
psql -U postgres -d test -c "select pglogical.create_replication_set('replication_set');"
psql -U postgres -d test -c "select pglogical.replication_set_add_table(
  set_name := 'replication_set',
  relation := 'slm',
  synchronize_data := true
);"
