# Rabbit Classic Cluster

This docker image can be used to establish a rabbit cluster using the [classic clustering method](https://www.rabbitmq.com/cluster-formation.html).
Classic cluster is a hardcoded list of nodes which you want to form part of the cluster so you can't do dynamic scaling easily, this is more about maintaining high availability

## How it works

All nodes are started at the same time and a standoff occurs on the first startup. All of the nodes will try to connect to the cluster, until one node hits its retry limit and forms its own cluster. The other nodes then form the cluster with this node. This way we don't have to have a single node which is configured differently to the rest.

To configure a user and enable replication we need to wait for this to complete. To perform this configuration the entrypoint script includes a background task chain of steps. The first step in background tasks waits for the rabbit_mq cluster to form and once this has completed it starts the configuration of the app.

This does take a little while ( 2 - 3 minutes ) to completely finish. But it does create a highly available cluster without having to perform any manual configuration.

## Configuration

To create a cluster you just need to tell the docker image the node addresses. The image updates the config file on each boot and uses environment variables to set the nodes
The environment variable name for the cluster nodes follows the following format

`CLUSTER_NODENAME_<a unique string>`

Where the unique string identifies the node in the cluster. You can have as many nodes as you want in the cluster, just keep adding env vars with `CLUSTER_NODENAME_`

See the docker-compose file for an example cluster with 3 nodes

Env vars

| Name | Description |
|------|-------------|
| RABBITMQ_NODENAME | sets the name of node |
| CLUSTER_NAME | sets the name of the rabbit cluster |
| APP_USER_ID  | sets the username of the default app user |
| APP_USER_PASSWORD | sets the password of th deffault app user |
| APP_USER_VHOST | sets the name of the vhost the app user will have full access to |
| CLUSTER_REPLICA_QUEUE_PATTERN | a regex pattern to specify which queues should be replicated in the HA cluster default: (.*) |
| CLUSTER_VHOST_PATTERN | A regex patter n to specify which vhosts should be replicated in the the HA Cluster ( default: .* )
| AWS_REGION | The region the cluster is deployed ( for KMS encrypted secrets only ) |
| KMS_PREFIX | A prefix at the start of the encrypted environment variables to show that it is encrypted with kms ( default: kms_base64: ) |
| RUN_BACKGROUND_TASKS | Enable or disable the background tasks used to bootstrap the rabbitcluster |
