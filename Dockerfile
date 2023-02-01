# build lodestone stage
FROM ubuntu:jammy as builder

# environment settings
ARG LODESTONE_VERSION
ENV HOME="/root"

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    curl \
    gnupg2 \
    jq \
    libssl-dev \
    pkg-config && \
  curl https://sh.rustup.rs -sSf | sh -s -- -y && \
  . /root/.cargo/env && \
  echo "**** download lodestone ****" && \
  mkdir -p \
    /tmp/lodestone \
    /out && \
  if [ -z ${LODESTONE_VERSION} ]; then \
    LODESTONE_VERSION=$(curl -sL https://api.github.com/repos/Lodestone-Team/lodestone_core/releases/latest | \
      jq -r '.tag_name'); \
  fi && \
  curl -o \
    /tmp/lodestone.tar.gz -L \
    "https://github.com/Lodestone-Team/lodestone_core/archive/${LODESTONE_VERSION}.tar.gz" && \
  tar xf \
    /tmp/lodestone.tar.gz -C \
    /tmp/lodestone --strip-components=1 && \
  cd /tmp/lodestone && \
    cargo build --release && \
    cargo install --path . --root /out

# runtime stage
FROM ghcr.io/imagegenius/baseimage-ubuntu:jammy

# set version label
ARG BUILD_DATE
ARG VERSION
ARG LODESTONE_VERSION
LABEL build_version="ImageGenius Version:- ${VERSION} Build-date:- ${BUILD_DATE}"
LABEL maintainer="hydazz"

# environment settings
ENV LODESTONE_PATH=/config

COPY --from=builder /out/bin /app/lodestone

RUN \
  apt-get update && \
  apt-get install -y --no-install-recommends \
    cpuidtool \
    libcpuid-dev \
    libssl-dev && \
  echo "**** cleanup ****" && \
  apt-get clean && \
  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# copy local files
COPY root/ /

# ports and volumes
EXPOSE 16662
VOLUME /config
