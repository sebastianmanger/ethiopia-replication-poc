#!/bin/sh

# Setup this 'node'
psql -U postgres -d test -c "SELECT pglogical.drop_node('region_one', true);"
psql -U postgres -d test -c "SELECT pglogical.create_node(
    node_name := 'region_one',
    dsn := 'host=region_one port=5432 dbname=test user=replication'
);"

# Create a dummy table.
psql -U postgres -d test -c "DROP TABLE IF EXISTS slm"
psql -U postgres -d test -c "CREATE TABLE slm (
    uuid    uuid primary key,
    public  bool DEFAULT true,
    name    varchar(40),
    region_specific varchar(10) DEFAULT 'test'
);"

# Subscribe to the node 'district_one'
# 'subscription_name' must match the name of the subscription (so this should be unique amongst all nodes)
# 'replication_sets' must match the name of the set on district node
psql -U postgres -d test -c "SELECT pglogical.drop_subscription('district_one_test', true);"
psql -U postgres -d test -c "SELECT pglogical.create_subscription(
    subscription_name := 'district_one_test',
    replication_sets := array['replicate_db_test'],
    provider_dsn := 'host=district_one port=5432 dbname=test user=replication'
);"

# Subscribe to the node 'district_two'
psql -U postgres -d test -c "SELECT pglogical.drop_subscription('district_two_test', true);"
psql -U postgres -d test -c "SELECT pglogical.create_subscription(
    subscription_name := 'district_two_test',
    replication_sets := array['replicate_db_test'],
    provider_dsn := 'host=district_two port=5432 dbname=test user=replication'
);"
