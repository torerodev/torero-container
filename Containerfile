# Use official Python slim image as base
ARG PYTHON_VERSION=3.13.0
FROM python:${PYTHON_VERSION}-slim-bookworm

LABEL maintainer="torerodev <opensource@itential.com>"
LABEL org.opencontainers.image.source="https://github.com/torerodev/torero-container"
LABEL org.opencontainers.image.description="torero container image"
LABEL org.opencontainers.image.licenses="Apache-2.0"

# default locale
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# default version
ARG TORERO_VERSION=1.4.0
ENV TORERO_VERSION=${TORERO_VERSION}

# default opentofu version (can be overridden at runtime)
ENV OPENTOFU_VERSION=1.9.1
ENV INSTALL_OPENTOFU=true

# ssh access is disabled by default
ENV ENABLE_SSH_ADMIN=false

# torero eula auto-acceptance is enabled by default
ENV TORERO_APPLICATION_AUTO_ACCEPT_EULA=true

# MCP server is disabled by default
ENV ENABLE_MCP=false

# MCP server default configuration
ENV TORERO_MCP_TRANSPORT_TYPE=sse
ENV TORERO_MCP_TRANSPORT_HOST=0.0.0.0
ENV TORERO_MCP_TRANSPORT_PORT=8080
ENV TORERO_MCP_TRANSPORT_PATH=/sse
ENV TORERO_API_BASE_URL=http://localhost:8000
ENV TORERO_API_TIMEOUT=30
ENV TORERO_LOG_LEVEL=INFO
ENV TORERO_MCP_PID_FILE=/tmp/torero-mcp.pid
ENV TORERO_MCP_LOG_FILE=/home/admin/.torero-mcp.log

# reduce docker image size
ENV DEBIAN_FRONTEND=noninteractive

# copy scripts to image
COPY configure.sh /configure.sh
COPY entrypoint.sh /entrypoint.sh

# make executable, run configuration script
RUN chmod +x /configure.sh && /configure.sh && \
    chmod +x /entrypoint.sh

# expose ssh port (only used if SSH is enabled)
EXPOSE 22

# expose MCP port (only used if MCP is enabled)
EXPOSE 8080

# create volume for persistent data
VOLUME ["/home/admin/data"]

# healthcheck - is torero functional?
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD torero version || exit 1

# set entrypoint
ENTRYPOINT ["/entrypoint.sh"]

# default command depends on SSH being enabled
CMD ["/bin/bash", "-c", "if [ \"$ENABLE_SSH_ADMIN\" = \"true\" ]; then /usr/sbin/sshd -D; else tail -f /dev/null; fi"]