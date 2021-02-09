# postgres-bdr
postgres-bdr using alpine image

## version
postgres 9.4

## Executar comandos no container
 psql --user postgres

[BDR project doc](http://bdr-project.org/docs/stable/functions-node-mgmt.html)

[tutorial 1](https://yenthanh.medium.com/multi-master-replication-for-postgresql-databases-with-postgres-bdr-eb6d8b1bc189)

[tutorial 2](https://gist.github.com/RafaelMCarvalho/4d5cce26a45d1d5f87d0643a699d41c2)

## Passos usando psql

1. criar usuário de replicação

    > psql -c "CREATE USER bdrsync superuser;"
    
    > psql -c "ALTER USER bdrsync WITH PASSWORD '12345#';"
        
2. criar banco a ser replicado

    > psql -c "CREATE DATABASE teste_db;"
    
3. usando o banco criado adicionar as extensões `btree_gist` e `bdr`
   
   > psql teste_db -c 'CREATE EXTENSION btree_gist;'
   
   > psql teste_db -c 'CREATE EXTENSION bdr;'
    
4. criar grupo no master
       
      > psql
       \c teste_db
       SELECT bdr.bdr_group_create(
           local_node_name := 'master',
           node_external_dsn := 'host=IP_MASTER_NODE port=5432 user=bdrsync dbname=teste_db password=12345#'
       ); 

5. juntar ao grupo na master
    
    >  psql
       \c teste_db
       SELECT bdr.bdr_group_join(
            local_node_name := 'worker',
            node_external_dsn := 'host=IP_WORKER_NODE user=bdrsync port=5432  dbname=test_db password=12345#',
            join_using_dsn := 'host=IP_MASTER_NODE user=bdrsync port=5432  dbname=test_db password=12345#'
        );


## ENV 
- POSTGRES_PASSWORD
- POSTGRES_USER
- POSTGRES_HOST_AUTH_METHOD
- ...

# RUN

> docker run -e POSTGRES_PASSWORD=password -p 5432:5432 -d juniorzilles/postgres-bdr:latest
