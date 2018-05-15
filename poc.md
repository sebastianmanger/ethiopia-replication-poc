# Proof of concept

These docker provides following:

    * Asynchronous synchronization of upates
    * 'Upstream' synchronization (district -> region -> nation)
    * Row filtering
    * Example for configuration
    * A text in *italics* indicates that this can be looked up in this repository.

## Summary

The 'starting point' is the file: ```docker-compose.yml```
This file starts multiple containers, each representing one (isolated) datacentre. 

When running the containers (see: run), the required setup for pglocial should become clear.

## Run proof of concept

* Install [Docker](https://docker.com)
* In the terminal, run ```docker-compose up```
* Connect to the region_one node - the data synchronized from district_one!
* More data can be added, e.g. 

    * ```docker exec -it ethiopiapglogical_district_one_1 psql -U postgres -d test -c "INSERT INTO slm (2, 'another row')"```
    * This data is now synchronized 'upstream'

## System configuration

### Preparation and dependencies

* See: https://www.2ndquadrant.com/en/resources/pglogical/pglogical-installation-instructions/

    * *Dockerfile, lines 8-12*
    
* Enable the extension: ```psql -U postgres -d <your database> -c 'CREATE EXTENSION IF NOT EXISTS pglogical;' ```
    
    * *entrypoint.sh, line 11*
    
* Add a superuser for replication: ```psql -U postgres -c 'CREATE ROLE replication_user WITH SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD "<your password here>";' ```

    * *entrypoint.sh, line 13*

### Configuration

* See: https://www.2ndquadrant.com/en/resources/pglogical/pglogical-docs/ for the full documentation.
* Get path to config with: ```psql -c "SHOW config_file;" "```
* 'postgresql.conf' contains the configuration of your cluster. Append the following to enable pglogical:
    
    * wal_level = 'logical'
    * shared_preload_libraries = pglogical 
    * listen_addresses = '*'  --> provide the specific addresses here in production!
    * max_replication_slots = 10
    * max_wal_senders = 10
    * max_worker_processes = 10
    * track_commit_timestamp = on
    * *See pgdata/postgresql.conf*
    
* pg_hba.conf contains the client authentication file. Append the following:

    * "host    replication          <your db>                <host string>   md5"
    * "host    replication          <your db>                <host string>   md5"
    * See *pgdata/pg_hba.conf* 

### Create a node (one per datacentre)

* Make sure to replace all variables in the following command.

  * The name must be distinctive (unique over all datacentres). Use your hostname or such.
  * The dsn is the connection string, this must be available from 'outside'.
  
* ```psql -U postgres -d <your_database> -c "SELECT pglogical.create_node(node_name := '$name', dsn := 'host=$host port=$port dbname=$database_name user=replication_user password=$replication_user_password');"```

    * See *<district_one>/setup.sh, line 5*

### Define replication sets

* Limit the tables that are synchronized.
* This command is the same for all datacentres, but needs to be well defined and based on the application.

    * See *<district_one>/setup.sh, line 20*

## Add subscriptions

* A subscription defines the connection of two nodes.

    * See *<region_one>/setup.sh, line 18*

### Optional: row filtering

* See
