#!/bin/bash

set -e

function wait_for_bg_step {
    local bg_after="$1"; shift

    # Each BG task waits until the bg status file matches the task number it runs after
    # When this is found the task will be run and it updates its status
    max_retries=30
    retries=0
    while true; do

        if [[ "$( cat "${BG_ENTRYPOINT_STATUS}" )" == "${bg_after}" ]]; then
            break
        fi

        if [[ "${retries}" == "${max_retries}" ]]; then
            echo "$ME: Rabbit not available after $max_retries attempts"
            return 255
        fi

        sleep 10s
    done

    return 0
}
export -f wait_for_bg_step

function update_bg_status {
    local me="$1"; shift

    echo "$(echo "${me}" | cut -f1 -d"-")" > "${BG_ENTRYPOINT_STATUS}"
}
export -f update_bg_status

if [ -z "${RABBIT_ENTRYPOINT_QUIET_LOGS:-}" ]; then
    exec 3>&1
else
    exec 3>/dev/null
fi

RUN_BACKGROUND_TASKS="${RUN_BACKGROUND_TASKS:-"true"}"

# Decrypt Base64 encoded string encrypted using AWS KMS CMK keys
AWS_REGION="${AWS_REGION:-""}"
KMS_PREFIX="${KMS_PREFIX:-"kms+base64"}:"

echo >&3 "$0: Decrypting Secrets"
for ENV_VAR in $( printenv ); do
    KEY="$( echo "${ENV_VAR}" | cut -d'=' -f1)"
    VALUE="$( echo "${ENV_VAR}" | cut -d'=' -f2-)"

    if [[ -n "${AWS_REGION}" && $KEY != "KMS_PREFIX" && $VALUE == "${KMS_PREFIX}"* ]]; then
        echo >&3 "$0: AWS KMS - Decrypting Key ${KEY}"
        CIPHER_BLOB_PATH="/tmp/ENV-${KEY}-cipher.blob"
        echo ${VALUE#"${KMS_PREFIX}"} | base64 -d > "${CIPHER_BLOB_PATH}"
        VALUE="$(aws --region "${AWS_REGION}" kms decrypt --ciphertext-blob "fileb://${CIPHER_BLOB_PATH}" --output text --query Plaintext | base64 -d )"
        if [[ -n "${VALUE}" ]]; then
            export "${KEY}"="${VALUE}"
        else
            echo >&3 "$0: Warning: ${KEY} could not be decrypted"
        fi
    fi
done
echo >&3 "$0: Secrets Complete"

# Run Setup scripts and scheduled background tasks which wait for particular events
if [ "$1" = "rabbitmq-server" ]; then
    if /usr/bin/find "/docker-entrypoint.d/" -mindepth 1 -maxdepth 1 -type f -print -quit 2>/dev/null | read v; then
        echo >&3 "$0: /docker-entrypoint.d/ is not empty, will attempt to perform configuration"

        echo >&3 "$0: Looking for shell scripts in /docker-entrypoint.d/"
        find "/docker-entrypoint.d/" -follow -type f -print | sort -n | while read -r f; do
            case "$f" in
                *.bg.sh)
                    if [[ "${RUN_BACKGROUND_TASKS}" == "true" ]]; then
                        if [ -x "$f" ]; then
                            echo >&3 "$0: Launching $f as a background task";
                            "$f" &
                        else
                            # warn on shell scripts without exec bit
                            echo >&3 "$0: Ignoring $f, not executable";
                        fi
                    fi
                    ;;
                *.sh)
                    if [ -x "$f" ]; then
                        echo >&3 "$0: Launching $f";
                        "$f"
                    else
                        # warn on shell scripts without exec bit
                        echo >&3 "$0: Ignoring $f, not executable";
                    fi
                    ;;
                *) echo >&3 "$0: Ignoring $f";;
            esac
        done

        echo >&3 "$0: Configuration complete; ready for start up"
    else
        echo >&3 "$0: No files found in /docker-entrypoint.d/, skipping configuration"
    fi
fi

# dot source the rabbitmq entrypoint script that comes with the container
. docker-entrypoint.sh
