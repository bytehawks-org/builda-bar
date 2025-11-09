ARG ALPINE_VERSION=3.20
ARG VARIANT_NAME=stable

FROM alpine:${ALPINE_VERSION} as base

ARG ALPINE_VERSION
ARG VARIANT_NAME
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.opencontainers.image.title="builda-bar"
LABEL org.opencontainers.image.description="ByteHawks build orchestration container - Alpine ${VARIANT_NAME} (${ALPINE_VERSION})"
LABEL org.opencontainers.image.url="https://github.com/bytehawks/bytehawks"
LABEL org.opencontainers.image.source="https://github.com/bytehawks/bytehawks"
LABEL org.opencontainers.image.documentation="https://github.com/bytehawks/bytehawks/wiki/builda-bar"
LABEL org.opencontainers.image.vendor="ByteHawks"
LABEL org.opencontainers.image.licenses="Apache-2.0"
LABEL org.opencontainers.image.created="${BUILD_DATE}"
LABEL org.opencontainers.image.revision="${VCS_REF}"
LABEL org.opencontainers.image.version="${VERSION}"
LABEL alpine.variant="${VARIANT_NAME}"
LABEL alpine.version="${ALPINE_VERSION}"
LABEL org.opencontainers.image.authors="ByteHawks Contributors"

RUN apk update && apk add --no-cache \
    linux-headers \
    ansible \
    gcc \
    make \
    cmake \
    perl \
    python3 \
    py3-pip \
    git \
    curl \
    wget \
    musl-dev \
    ca-certificates \
    git-perl \
    bash \
    coreutils \
    findutils \
    grep \
    sed

#RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel

WORKDIR /build

ENV PATH="/usr/local/bin:$PATH"
ENV PYTHONUNBUFFERED=1
ENV ALPINE_VERSION="${ALPINE_VERSION}"
ENV VARIANT_NAME="${VARIANT_NAME}"
ENV BUILD_CONTAINER="builda-bar"

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["/bin/bash"]
