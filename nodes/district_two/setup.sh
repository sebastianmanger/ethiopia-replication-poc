#!/bin/sh

# Setup this 'node'
psql -U postgres -d test -c "SELECT pglogical.drop_node('district_two', true)"
psql -U postgres -d test -c "SELECT pglogical.create_node(
    node_name := 'district_two',
    dsn := 'host=district_two port=5432 dbname=test user=replication'
);"

# Create a dummy table
psql -U postgres -d test -c "DROP TABLE IF EXISTS slm"
psql -U postgres -d test -c "CREATE TABLE slm (
    uuid    uuid primary key DEFAULT uuid_generate_v4(),
    public  bool,
    name    varchar(40)
);"
# This is the data that is 'replicated' to all nodes that have a subscription to this node.
psql -U postgres -d test -c "INSERT INTO slm values (uuid_generate_v4(), true, 'district two: first public entry');"
psql -U postgres -d test -c "INSERT INTO slm values (uuid_generate_v4(), false, 'district two: first non-public entry');"
psql -U postgres -d test -c "INSERT INTO slm values (uuid_generate_v4(), true, 'district two: second public entry');"

# Provide data for 'subscribers' (in this case: region_one)
psql -U postgres -d test -c "select pglogical.create_replication_set('replicate_db_test');"
psql -U postgres -d test -c "select pglogical.replication_set_add_table(
  set_name := 'replicate_db_test',
  relation := 'slm',
  synchronize_data := true,
  row_filter := 'public = true',
  columns := array['uuid', 'name']
);"
