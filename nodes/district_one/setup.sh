#!/bin/sh

# Setup this 'node'
psql -U postgres -d test -c "SELECT pglogical.drop_node('district_one', true)"
psql -U postgres -d test -c "SELECT pglogical.create_node(
    node_name := 'district_one',
    dsn := 'host=district_one port=5432 dbname=test user=replication'
);"

# Create a dummy table.
# Note: this table has an additional column: 'tmp'. As this is not set in 'columns' for the replication set (see below)
# this is not replicated --> this means that not all nodes must use an identical scheme - and the PHP application
# which provides the schema changes may be newer on some nodes than on others.
psql -U postgres -d test -c "DROP TABLE IF EXISTS slm"
psql -U postgres -d test -c "CREATE TABLE slm (
    uuid    uuid primary key DEFAULT uuid_generate_v4(),
    public  bool,
    name    varchar(40),
    tmp     varchar(40),
    parent  uuid NULL
);"
# This is the data that is 'replicated' to all nodes that have a subscription to this node.
psql -U postgres -d test -c "INSERT INTO slm values (uuid_generate_v4(), true, 'district one: first public entry', 'this is not in the replication');"
psql -U postgres -d test -c "INSERT INTO slm values (uuid_generate_v4(), false, 'district one: first non-public entry', 'this not in the replication');"
psql -U postgres -d test -c "INSERT INTO slm values (uuid_generate_v4(), true, 'district two: second public entry', 'this is in the replication, with parent', '4f6df35c-324e-461e-a6c3-95e36fb0392c');"

# Provide data for 'subscribers' (in this case: region_one)
psql -U postgres -d test -c "select pglogical.create_replication_set('replicate_db_test');"
psql -U postgres -d test -c "select pglogical.replication_set_add_table(
  set_name := 'replicate_db_test',
  relation := 'slm',
  synchronize_data := true,
  row_filter := 'public = true',
  columns := array['uuid', 'name', 'parent']
);"
