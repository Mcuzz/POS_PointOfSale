FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

ARG FLUTTER_CHANNEL=stable

ENV DEBIAN_FRONTEND=noninteractive \
    FLUTTER_HOME=/opt/flutter \
    PUB_CACHE=/home/vscode/.pub-cache \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Dependencias del sistema para Flutter (Web, Linux Desktop y SQLite FFI)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    clang \
    cmake \
    curl \
    git \
    gnupg \
    libglu1-mesa \
    libgtk-3-dev \
    liblzma-dev \
    libsqlite3-dev \
    ninja-build \
    pkg-config \
    unzip \
    xz-utils \
    zip \
    && rm -rf /var/lib/apt/lists/*

# Node.js LTS y Firebase CLI para hosting/emuladores (firebase.json)
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y --no-install-recommends nodejs \
    && npm install -g firebase-tools \
    && npm cache clean --force \
    && rm -rf /var/lib/apt/lists/*

# Instalación de Flutter SDK
RUN git clone --depth 1 --branch "${FLUTTER_CHANNEL}" https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && git config --system --add safe.directory "${FLUTTER_HOME}" \
    && mkdir -p "${PUB_CACHE}" \
    && chown -R vscode:vscode "${FLUTTER_HOME}" "${PUB_CACHE}"

USER vscode

RUN flutter config --no-analytics --enable-web --enable-linux-desktop \
    && dart --disable-analytics \
    && flutter precache --web --linux
