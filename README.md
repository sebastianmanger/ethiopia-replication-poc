# SLM knowledge management: data synchronization/replication proof of concept

This is a proof of concept for data replication on database level between various levels (district, region, nation).
By using the postgresql extension pglogical, no additional (new) systems such as elasticsearch are required.
This guide requires knowledge for system administration and specifically database administration. 

## Goals

* Synchronize data asynchronously, flaky connectivity is expected.
* Technically robust solution, keeping additional complexity low.
* Low bandwidth usage, synchronize only updates ('difference') of approved data.

## Limitations 

* No two-way synchronization. The only way is upstream: district to region to nation.

  * This implies that approving data must always be done on district level, and then synchronized 'upstream'
  * Two-way synchronization is theoretically possible, but will lead in data conflicts: the same data can be edited at 
    same time in three different levels. This increases complexity massively, not only for development, but also
    for ongoing management.
  * If the application links to the proper level for editing (always district), this should not be bothering the users.
  
    * In the application: always link to the domain of the district when editing data.

* If a datacentre remains offline for a long time, the hard disk will run out of space.
  
  * Local updates are kept as 'write ahead logs', and cleaned only after completed synchronization.
  * See: Requirements --> monitoring.

## Requirements

* postgresql as database backend

    * UUID as primary keys for all tables that are synchronized. This is required, so the same ID is not used in 
    multiple districts. See https://www.postgresql.org/docs/current/static/uuid-ossp.html and 
    https://docs.zendframework.com/zend-validator/validators/uuid/
    * This change (ID as UUID) is the only change required at application (PHP) level

* Monitoring: following data must be closely monitored:

    * Online status of all applications (web server and database server)
    * Replication status
    * Free space on hard drive, size of '[WAL](https://www.postgresql.org/docs/10/static/wal-intro.html)' files
    * Monitoring should be up and running from the start, as a learning curve is to be expected
    * CDE can provide insight about monitoring.

## Solution

Use pglogical (https://www.2ndquadrant.com/en/resources/pglogical/pglogical-docs/) for replication. 

* Reason:

    * Well maintained, easy installation and usage as postgresql extension.
    * Synchronize data from 'write ahead log' - so only the updates to the database, not a 'full' replication.
    * Works well with bad connectivity.
    * Row filtering is possible, so only 'approved' data may be synced.

* Rejected alternatives:

    * Elasticsearch: would require massive refactor of the application, and adds a whole new tool - with its own challenges
    * Built-in synchronization of postgresqlql: can't sync between different releases; 'full' sync only
    * BDR: requires custom build of postgresql, more sophisticated and complex than pglogical
    * slony/bucardo/...: some of them are not well maintained, none of them uses the built in methods of postgresql.
    
## Terms

* **Node**: A postgres server on a datacenter. Each server/datacenter is a node.

* **Subscription**: The connection between a provider node and a replication node. A node can serve as replication node
  and providing node. E.g. the regional datacenter subscribes to all its district datacentres. 
 
* **Replication set**: The set of tables defined for synchronization. So not the full database, but only selected tables.

* **Row filtering**: Within the selected replication sets, the rows to replicate can be limited with a row filter.
  This may be used to synchronize 'approved' data only, and thereby reducing bandwith usage. 


## Run Proof of concept

For those interested: install Docker (https://docker.com) and run```docker-compose up```

See [poc.md](poc.md)for detailed information.


## Disbling orphans

pglogical does not guarantee the order of replication, so children may be replicated before its parents (see pglogical 
docs, item 4.8 FOREIGN KEYS). To avoid application errors, following procedure is recommended:

* A new column is introduced: ```is_active```. The application should only display values where this is ```true```.
* A trigger checks the availability foreign key, an sets ```is_active``` to ```false``` if unsuccessful. See the trigger
in the setup of region one (```nodes/region_one/setup.sh, line 36```).
* A cronjob is created: check all foreign keys where ```is_active``` is ```false``` and enable it if the parent is now 
available. This cronjob is not in the repository, but should be straightforward to develop.
