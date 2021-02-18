FROM rabbitmq:3-management-alpine

RUN apk update \
    && apk add gettext aws-cli

COPY rabbitmq.conf.template /etc/rabbitmq/

COPY --chown=rabbitmq:rabbitmq 10-set-nodename-hostname.sh /docker-entrypoint.d/
COPY --chown=rabbitmq:rabbitmq 20-envsubst-on-config.sh /docker-entrypoint.d/
COPY --chown=rabbitmq:rabbitmq 30-cluster-setup.sh /docker-entrypoint.d/
COPY --chown=rabbitmq:rabbitmq 100-running-wait.bg.sh /docker-entrypoint.d/
COPY --chown=rabbitmq:rabbitmq 105-cluster-name.bg.sh /docker-entrypoint.d/
COPY --chown=rabbitmq:rabbitmq 110-create-user.bg.sh /docker-entrypoint.d/
COPY --chown=rabbitmq:rabbitmq 120-cluster-config.bg.sh /docker-entrypoint.d/

## Setup a background pid file to sequence background tasks
ENV BG_ENTRYPOINT_STATUS=/docker-entrypoint.d/sh_bg.status
RUN echo "0" > "${BG_ENTRYPOINT_STATUS}"
RUN chown rabbitmq:rabbitmq "${BG_ENTRYPOINT_STATUS}"

RUN  chmod ugo+x /docker-entrypoint.d/*.sh

COPY --chown=rabbitmq:rabbitmq docker-config-entrypoint.sh /usr/local/bin/
RUN  chmod ugo+x /usr/local/bin/docker-config-entrypoint.sh

ENV RABBITMQ_VM_MEMORY_ABSOLUTE_HIGH_WATERMARK "256MB"
ENV LOG_LEVEL "info"

ENTRYPOINT [ "docker-config-entrypoint.sh" ]
CMD ["rabbitmq-server"]
