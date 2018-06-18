#!/bin/sh

# Setup this 'node'
psql -U postgres -d test -c "SELECT pglogical.drop_node('region_one', true);"
psql -U postgres -d test -c "SELECT pglogical.create_node(
    node_name := 'region_one',
    dsn := 'host=region_one port=5432 dbname=test user=replication'
);"

# Create dummy tables.
psql -U postgres -d test -c "DROP TABLE IF EXISTS slm"
psql -U postgres -d test -c "DROP TABLE IF EXISTS parent_table"
psql -U postgres -d test -c "CREATE TABLE parent_table (
    uuid    uuid primary key
);"
psql -U postgres -d test -c "CREATE TABLE slm (
    uuid    uuid primary key,
    public  bool DEFAULT true,
    name    varchar(40),
    is_active    bool DEFAULT false,
    parent  uuid NULL,
    region_specific varchar(10) DEFAULT 'test'
);"
# Add a foreign key.
psql -U postgres -d test -c "ALTER TABLE slm
    ADD CONSTRAINT slm_fk
    FOREIGN KEY (parent)
    REFERENCES parent_table (uuid)
    MATCH FULL;
"
# Enable a single entry in the parent table - only children with this
# parent must be 'is_active'
psql -U postgres -d test -c "INSERT INTO parent_table values ('4f6df35c-324e-461e-a6c3-95e36fb0392c');"

# Add a new function: set data without 'parents' replicated to 'is_active=False',
# this column can then be queried for in the application.
# 'NEW' is the value that is replicated, and must be returned
psql -U postgres -d test -c "
CREATE FUNCTION deactivate_orphans()
RETURNS trigger AS '
BEGIN
  NEW.IS_ACTIVE = EXISTS(SELECT 1 FROM parent_table WHERE uuid=NEW.PARENT);
  RETURN NEW;
END' LANGUAGE 'plpgsql'"

# Activate a trigger for 'before insert', calling the function defined above.
# https://www.2ndquadrant.com/en/resources/pglogical/pglogical-docs/
# "On the subscriber the row based filtering can be implemented using standard BEFORE TRIGGER mechanism."
psql -U postgres -d test -c "
CREATE TRIGGER clear_orphans
BEFORE INSERT ON slm FOR EACH ROW
EXECUTE PROCEDURE deactivate_orphans()"
psql -U postgres -d test -c "ALTER TABLE slm ENABLE REPLICA TRIGGER clear_orphans;"

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
