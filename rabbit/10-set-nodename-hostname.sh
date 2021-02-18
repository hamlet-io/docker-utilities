#!/bin/bash

set -e

ME=$(basename $0)

nodename_hostname() {
    if [[ -n "${RABBITMQ_NODENAME}" ]]; then
        echo "$ME: Adding nodename to host file for local resolution"
        echo "127.0.0.1 ${RABBITMQ_NODENAME//rabbit@/}" >> /etc/hosts
    fi
}

nodename_hostname
exit 0
