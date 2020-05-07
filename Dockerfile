FROM php:7.4.3-apache
# Apache https://github.com/docker-library/php/blob/04c0ee7a0277e0ebc3fcdc46620cf6c1f6273100/7.4/buster/apache/Dockerfile

ENV CONFD_VERSION="0.16.0" \
    CONFD_SHA256="255d2559f3824dd64df059bdc533fd6b697c070db603c76aaf8d1d5e6b0cc334" \
    S6_OVERLAY_VERSION=${S6_OVERLAY_VERSION:-1.22.1.0}

ADD https://github.com/just-containers/s6-overlay/releases/download/v$S6_OVERLAY_VERSION/s6-overlay-amd64.tar.gz /tmp/

## General Dependencies
RUN GEN_DEP_PACKS="software-properties-common \
    gnupg \
    zip \
    unzip \
    git" && \
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections && \
    apt-get update && \
    apt-get install --no-install-recommends -y $GEN_DEP_PACKS && \
    ## Cleanup phase.
    apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    ## Confd
    curl -sSfL -o /usr/local/bin/confd https://github.com/kelseyhightower/confd/releases/download/v${CONFD_VERSION}/confd-${CONFD_VERSION}-linux-amd64 && \
    sha256sum /usr/local/bin/confd | cut -f1 -d' ' | xargs test ${CONFD_SHA256} == && \
    chmod +x /usr/local/bin/confd
    ## s6
    tar xzf /tmp/s6-overlay-amd64.tar.gz -C / && \
    rm /tmp/s6-overlay-amd64.tar.gz && \
    ## Edit entrypoint to run confd
    sed -i '/set -e/a \\nconfd --onetime --backend env/' /usr/local/bin/docker-php-entrypoint

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="ISLE 8 Crayfish Base Image" \
      org.label-schema.description="ISLE 8 Crayfish Base" \
      org.label-schema.url="https://islandora.ca" \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/Islandora-Devops/isle-crayfish-base" \
      org.label-schema.vendor="Islandora Devops" \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

STOPSIGNAL SIGWINCH

EXPOSE 8000

CMD ["apache2-foreground"]
