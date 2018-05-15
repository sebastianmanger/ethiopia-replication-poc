#!/bin/sh

# Setup this 'node'
psql -U postgres -d test -c "SELECT pglogical.drop_node('region_one', true);"
psql -U postgres -d test -c "SELECT pglogical.create_node(
    node_name := 'region_one',
    dsn := 'host=region_one port=5432 dbname=test user=replication'
);"

# Create a dummy table
psql -U postgres -d test -c "CREATE TABLE slm (
    uuid    integer primary key,
    name    varchar(40)
);"

# Subscribe to the node 'district_one'
psql -U postgres -d test -c "SELECT pglogical.drop_subscription('district_one_test', true);"
psql -U postgres -d test -c "SELECT pglogical.create_subscription(
    subscription_name := 'district_one_test',
    replication_sets := array['replication_set'],
    provider_dsn := 'host=district_one port=5432 dbname=test user=replication'
);"
