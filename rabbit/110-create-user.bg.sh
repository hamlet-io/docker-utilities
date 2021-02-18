#!/bin/bash

set -e

ME=$(basename $0)

create_user() {

    APP_USER_ID="${APP_USER_ID:-"app-user"}"
    APP_USER_PASSWORD="${APP_USER_PASSWORD:-""}"
    APP_USER_VHOST="${APP_USER_VHOST:-"app-user"}"

    if [[ -n "${APP_USER_PASSWORD}" ]]; then

        user_list="$( rabbitmqctl list_users --silent | grep "${APP_USER_ID}" || [[ $? == 1 ]] )"
        if [[ -z "${user_list}" ]]; then
            echo "$ME: Creating user ${APP_USER} ..."
            rabbitmqctl add_user "${APP_USER_ID}" "${APP_USER_PASSWORD}"
        fi
        echo "$ME: Updating user details ..."
        rabbitmqctl change_password "${APP_USER_ID}" "${APP_USER_PASSWORD}"
        rabbitmqctl set_user_tags "${APP_USER_ID}" administrator

        vhost_list="$( rabbitmqctl list_vhosts --silent | grep "${APP_USER_VHOST}" || [[ $? == 1 ]] )"
        if [[ -z "${vhost_list}" ]]; then

            echo "$ME: Creating Vhost"
            rabbitmqctl add_vhost "${APP_USER_VHOST}"
        fi

        rabbitmqctl set_permissions -p "${APP_USER_VHOST}" "${APP_USER_ID}" ".*" ".*" ".*"
    fi
}

# Run this script after this one
wait_for_bg_step "105"

create_user

# Save script state for next bg task to watch
update_bg_status "${ME}"

exit 0
