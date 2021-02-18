#!/bin/bash

set -e

ME=$(basename $0)

cluster_setup() {
  local conf_file="/etc/rabbitmq/rabbitmq.conf"

  local cluster_nodes="$(printf '%s ' $(env | grep CLUSTER_NODENAME_ | cut -d= -f1))"
  read -ra cluster_nodes <<< "${cluster_nodes}"

  if [ -n "${cluster_nodes}" ]; then
    echo "$ME: setting up classic clustering with ${#cluster_nodes[@]} nodes"
    printf "## \n## Cluster Nodes \n## =====================\n" >> $conf_file
    printf "cluster_formation.peer_discovery_backend = classic_config\n" >> $conf_file

    for i in "${!cluster_nodes[@]}"; do
        node_id=$((i + 1 ))
        cluster_node_env="${cluster_nodes[$i]}"
        printf "cluster_formation.classic_config.nodes.${node_id} = ${!cluster_node_env}\n" >> $conf_file
    done
  fi
}

cluster_setup

exit 0
