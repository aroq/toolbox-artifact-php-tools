FROM aroq/variant:0.35.1 as variant
FROM mikefarah/yq:2.4.0 as yq
FROM aroq/toolbox-wrap:0.1.41 as toolbox-wrap
FROM aroq/toolbox-variant:0.1.50 as toolbox-variant
FROM aroq/toolbox-artifact:0.2.27 as toolbox-artifact

FROM michaeltigr/toolbox-php-tools:7.3-8-0.2.1.2

# Install alpine package manifest
COPY Dockerfile.packages.txt /etc/apk/packages.txt
RUN apk add --no-cache --update $(grep -v '^#' /etc/apk/packages.txt)

RUN mkdir -p /toolbox && \
    git clone -b v0.1.10 --depth=1 --single-branch https://github.com/aroq/toolbox-utils.git /toolbox/toolbox-utils && \
    git clone -b v0.1.7  --depth=1 --single-branch https://github.com/aroq/toolbox-exec.git /toolbox/toolbox-exec && \
    rm -fR /toolbox/toolbox-utils/.git && \
    rm -fR /toolbox/toolbox-exec/.git

COPY --from=yq /usr/bin/yq /usr/bin/yq
COPY --from=variant /usr/bin/variant /usr/bin/
COPY --from=toolbox-wrap /usr/local/bin/fd /usr/local/bin/
# COPY --from=toolbox-wrap /toolbox/toolbox-wrap /toolbox
# COPY --from=toolbox-variant /toolbox/toolbox-variant /toolbox
COPY --from=toolbox-variant /entrypoint.sh /entrypoint.sh
COPY --from=toolbox-variant /entrypoint.vars.sh /entrypoint.vars.sh
COPY --from=toolbox-artifact /root/.ssh/config /root/.ssh/config
COPY --from=toolbox-artifact /toolbox/ /toolbox/

RUN chown root:root /root/.ssh/config && chmod 600 /root/.ssh/config

ENV VARIANT_HIDE_EXTRA_CMDS true
ENV VARIANT_LOG_LEVEL warning
ENV VARIANT_CONFIG_CONTEXT toolbox
ENV VARIANT_CONFIG_DIR toolbox

ENV TOOLBOX_DEPS_DIR /toolbox
ENV TOOLBOX_TOOL_DIRS toolbox,/toolbox/toolbox-artifact

ENTRYPOINT ["/entrypoint.sh"]
