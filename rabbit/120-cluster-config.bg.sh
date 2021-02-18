#!/bin/bash

# A post deployment script to set the queue
set -e

ME=$(basename $0)

configure_cluster() {
    APP_USER_VHOST="${APP_USER_VHOST:-"app-user"}"

    # Create default cluster replica policy
    cluster_nodes="$(printf '%s ' $(env | grep CLUSTER_NODENAME_ | cut -d= -f1))"
    read -ra cluster_nodes <<< "${cluster_nodes}"

    CLUSTER_REPLICA_QUEUE_PATTERN="${CLUSTER_REPLICA_QUEUE_PATTERN:-".*"}"
    CLUSTER_VHOST_PATTERN="${CLUSTER_VHOST_PATTERN:-"."}"

    if [ -n "${cluster_nodes}" ]; then
        cluster_node_count="${#cluster_nodes[@]}"

        echo "$ME: Creating queue replication policy based on ${cluster_node_count} nodes"

        readarray -t vhosts <<< "$( rabbitmqctl list_vhosts --silent | grep -e "${CLUSTER_VHOST_PATTERN}" || [[ $? == 1 ]] )"

        for vhost in "${vhosts[@]}"; do
            echo "$ME: Applying HA policy to $vhost"
            replica_count=$(( $cluster_node_count / 2 + 1 ))
            rabbitmqctl set_policy ha "${CLUSTER_REPLICA_QUEUE_PATTERN}"  --vhost "${vhost}" \
                "{\"ha-mode\":\"exactly\",\"ha-params\":${replica_count},\"ha-sync-mode\":\"automatic\"}" \
                --apply-to queues --priority 100
        done
    fi
}

# Run this script after this one
wait_for_bg_step "110"

configure_cluster

# Save script state for next bg task to watch
update_bg_status "${ME}"

exit 0
