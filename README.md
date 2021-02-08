# postgres-bdr
postgres-bdr using alpine image

## version
postgres 9.4

## Executar comandos no container
 psql --user postgres

[join node](http://bdr-project.org/docs/stable/functions-node-mgmt.html)

[tutorial 1](https://yenthanh.medium.com/multi-master-replication-for-postgresql-databases-with-postgres-bdr-eb6d8b1bc189)

[tutorial 2](https://gist.github.com/RafaelMCarvalho/4d5cce26a45d1d5f87d0643a699d41c2)

## Passos

1. criar usuário de replicação
    > CREATE USER bdrsync superuser;
    > ALTER USER bdrsync WITH PASSWORD '12345#';
2. criar banco
    > CREATE DATABASE teste_db;
3. com o banco selecionando adicionar as extensões `btree_gist` e `bdr`
    > CREATE EXTENSION btree_gist;
    > CREATE EXTENSION bdr;
4. criar grupo no master
    > 
    >  ```SELECT bdr.bdr_group_create(
    >    local_node_name := 'node1',
    >    node_external_dsn := 'host=192.168.56.101 user=bdrsync dbname=test_db password=12345#'
    >  );```
5. juntar ao grupo na master
    >
    >    ```SELECT bdr.bdr_group_join(
    >        local_node_name := 'node2',
    >        node_external_dsn := 'host=45.55.182.128 user=bdrsync dbname=test_db password=12345#',
    >        join_using_dsn := 'host=192.168.56.101 user=bdrsync dbname=test_db password=12345#'
    >    );```


## ENV 
- POSTGRES_PASSWORD
- POSTGRES_USER
- POSTGRES_HOST_AUTH_METHOD
- ...

# RUN

> docker run -e POSTGRES_PASSWORD=password -p 5432:5432 -d juniorzilles/postgres-bdr:latest
