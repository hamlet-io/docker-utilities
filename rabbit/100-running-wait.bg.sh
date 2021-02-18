set -e

ME=$(basename $0)

wait_for_running() {

    # Wait for rabbit to start up
    max_retries=30
    retries=0
    while true; do
        retries=$((retries+1))

        nc -zn localhost:4369 || continue
        rabbitmq-diagnostics check_running --silent && break

        if [[ "${retries}" == "${max_retries}" ]]; then
            echo "$ME: Rabbit not available after $max_retries attempts"
            exit 255
        fi

        sleep 5s
    done

}

wait_for_bg_step "0"

wait_for_running

# Save script state for next bg task to watch
update_bg_status "${ME}"

exit 0
