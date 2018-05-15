# Proof of concept

These docker containers provides following:

    * Asynchronous synchronization of upates
    * 'Upstream' synchronization (district -> region -> nation)
    * Row filtering
    * Column filtering
    * Example for configuration
    * A text in *italics* indicates that this can be looked up in this repository.

## Summary

The 'starting point' is the file: ```docker-compose.yml```
This file starts multiple containers, each representing one (isolated) datacentre. 

When running the containers (see: run), the required setup for pglocial should become clear.

## Run proof of concept

* Install [Docker](https://docker.com)
* In the terminal, run ```docker-compose up```
* Connect to the region_one node - all data from the districts is available!
    
    * ```docker exec -it ethiopiapglogical_region_one_1 psql -U postgres -d test -c "select * from slm;"```
    
* More data can be added, e.g. 

    * ```docker exec -it ethiopiapglogical_district_one_1 psql -U postgres -d test -c "INSERT INTO slm (...)"```
    * This data is now synchronized 'upstream' to the region

## System configuration

### Preparation and dependencies

* For pglogical, [refer to their docs](https://www.2ndquadrant.com/en/resources/pglogical/pglogical-installation-instructions/)

    * *Dockerfile, lines 8-12*
    
* Enable the extension: ```psql -U postgres -d <your database> -c 'CREATE EXTENSION IF NOT EXISTS pglogical;' ```
    
    * *entrypoint.sh, line 11*
    
* For UUID (on postgresql > 9), enable the [UUID extension](https://www.postgresql.org/docs/10/static/uuid-ossp.html): ```psql -U postgres -d <your database> -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp";' ```

    * *entrypoint.sh, line 14*
        
* Add a superuser for replication: ```psql -U postgres -c 'CREATE ROLE replication_user WITH SUPERUSER REPLICATION LOGIN ENCRYPTED PASSWORD "<your password here>";' ```

    * *entrypoint.sh, line 13*

### Configuration

* See [the docs](https://www.2ndquadrant.com/en/resources/pglogical/pglogical-docs/) for the full documentation.
* Get path to config with: ```psql -c "SHOW config_file;"```
* 'postgresql.conf' contains the configuration of your cluster. Append the following to enable pglogical:
    
    * wal_level = 'logical'
    * shared_preload_libraries = pglogical 
    * listen_addresses = '*'  --> provide the specific addresses here in production!
    * max_replication_slots = 10
    * max_wal_senders = 10
    * max_worker_processes = 10
    * track_commit_timestamp = on
    * *See pgdata/postgresql.conf*
    
* pg_hba.conf contains the client authentication file.
    
    * See *pgdata/pg_hba.conf*
    * Note: pg_hba must be set up in a secure/sane way. Use hostssl!

### Create a node (one per datacentre)

* This is done once per datacentre / database.
* The name must be distinctive (unique over all datacentres), use the hostname or something similar.
* The dsn is the connection string, this must be available from 'outside'.  
* ```psql -U postgres -d <your_database> -c "SELECT pglogical.create_node(node_name := '$name', dsn := 'host=$host port=$port dbname=$database_name user=replication_user password=$replication_user_password');"```

    * See *district_one/setup.sh, line 5*

### Define replication sets

* Limit the tables, rows (only published data) and columns that are synchronized.
* This command is the same for all datacentres, but needs to be well defined and based on the application.

    * See *district_one/setup.sh, line 27*

## Add subscriptions

* A subscription defines the connection of two nodes.
* I.e. the nation node will subscribe to all six region nodes, eaach region will subscribe to its districts.

    * See *region_one/setup.sh, line 23*

### Row and column filtering

* Row filtering is used to reduce bandwidth usage; only 'accepted' data should be synchronized.

    * See *district_one/setup.sh, line 32*
    
* Column filtering is used to reduce bandwidth usage, it also ensures that the various nodes may use different database schemes. This will happen if the application is updated, but not simultaneously on all nodes. 

    * See *district_one/setup.sh, line 33*
