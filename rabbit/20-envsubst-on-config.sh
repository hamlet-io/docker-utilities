#!/bin/bash

set -e

ME=$(basename $0)

auto_envsubst() {
  local template="/etc/rabbitmq/rabbitmq.conf.template"
  local output="/etc/rabbitmq/rabbitmq.conf"

  local defined_envs
  defined_envs=$(printf '${%s} ' $(env | cut -d= -f1))

  echo "$ME: Running envsubst on $template to $output"
  envsubst "$defined_envs" < "$template" > "$output"
}

auto_envsubst

exit 0
