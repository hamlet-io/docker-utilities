#!/bin/bash

# A post deployment script to set the queue
set -e

ME=$(basename $0)

set_cluster_name() {
    # Set the cluster name
    CLUSTER_NAME="${CLUSTER_NAME:-}"

    if [ -n "${CLUSTER_NAME}" ]; then
        echo "$ME: Setting cluster name to ${CLUSTER_NAME}"
        rabbitmqctl set_cluster_name "${CLUSTER_NAME}"
    fi
}


# Run this script after this one
wait_for_bg_step "100"

set_cluster_name

# Save script state for next bg task to watch
update_bg_status "${ME}"

exit 0
