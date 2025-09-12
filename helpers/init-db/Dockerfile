FROM alpine

# set version label
ARG VERSION=0.0.2
ARG BUILD_DATE
LABEL build_info="Version: ${VERSION} Build-date: ${BUILD_DATE}"
LABEL maintainer="Airlock Presales <noreply@airlock.com>"

RUN set -xe \
    && apk add --no-cache ca-certificates   \
    bash              \
    mariadb-client    \
    mysql-client      \
    postgresql-client \
    curl              \
    sed               \
    grep

# Setting User and Home
USER 1000
WORKDIR /var/tmp
ENV HOSTNAME=db-tools

# Running Bash
CMD ["/bin/bash"]
