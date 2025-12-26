FROM docker.io/library/alpine:latest AS certs

RUN apk add --no-cache --upgrade ca-certificates-bundle;

FROM docker.io/library/debian:trixie-20251208-slim AS build

COPY --from=certs /etc/ssl/certs/ca-certificates.crt \
    /etc/ssl/certs/ca-certificates.crt

ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ENV gl_cv_func_getcwd_path_max=yes

RUN sed -i \
        -e "s|^# http://snapshot.debian.org/archive/debian/20251208T000000Z$\
|URIs: https://snapshot.debian.org/archive/debian/20251208T000000Z|" \
        -e 's|^URIs: http://deb.debian.org/debian$|# &|' \
        -e "s|^# http://snapshot.debian.org/archive/debian-security/20251208T000000Z$\
|URIs: https://snapshot.debian.org/archive/debian-security/20251208T000000Z|" \
        -e 's|^URIs: http://deb.debian.org/debian-security$|# &|' \
        /etc/apt/sources.list.d/debian.sources;

RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99validity;

RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get update && \
    apt-get install --no-install-recommends -qy apt-eatmydata;

RUN DEBIAN_FRONTEND=noninteractive \
    apt-get install --no-install-recommends -qy  \
        bash \
        bc \
        binutils \
        build-essential \
        bzip2 \
        cpio \
        diffutils \
        file \
        findutils \
        g++ \
        gcc \
        gpgv \
        gzip \
        libelf-dev \
        make \
        mawk \
        patch \
        perl \
        rsync \
        sed \
        tar \
        unzip \
        wget \
        which && \
    rm -rf /var/lib/apt/lists/* && \
    mkdir /buildroot && \
    useradd -Us /bin/bash builder && \
    chown builder:builder /buildroot;

USER builder:builder
WORKDIR /buildroot

COPY buildroot-configs /buildroot-configs

ARG BR_ORIGIN="https://buildroot.org"
ARG BR_TARBALL="buildroot-2025.11.tar.gz"
ARG BR_SIGN="${BR_TARBALL}.sign"
ARG WGET_OPTS="-q --no-cookies --https-only --timeout=30 --tries=3"
ARG PUBKEY="pubkey.bin"

RUN wget $WGET_OPTS -O- ${BR_ORIGIN}/~jacmet/pubkey.gpg | \
    sed -n '/^$/,$p' | \
    grep -Ev '^(=|-)' | \
    base64 -d > $PUBKEY && \
    wget $WGET_OPTS ${BR_ORIGIN}/downloads/${BR_SIGN} && \
    gpgv --keyring ${PWD}/${PUBKEY} $BR_SIGN && \
    wget $WGET_OPTS ${BR_ORIGIN}/downloads/${BR_TARBALL} && \
    grep 'SHA256:' $BR_SIGN | \
    cut -d' ' -f2- | \
    sha256sum -c && \
    tar zxf $BR_TARBALL --strip-components=1 && \
    make defconfig BR2_DEFCONFIG=/buildroot-configs/buildroot.conf && \
    make && \
    mv /buildroot/output/images/bzImage /tmp && \
    find . -mindepth 1 -delete;

FROM scratch

COPY --from=build /tmp/bzImage /
