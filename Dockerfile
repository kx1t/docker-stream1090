# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, Ramon F. Kolb (kx1t) and contributors

ARG STREAM1090_REPO=https://github.com/mgrone/stream1090.git
ARG STREAM1090_REF=main

FROM debian:trixie-slim AS builder

# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, Ramon F. Kolb (kx1t) and contributors
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ARG STREAM1090_REPO
ARG STREAM1090_REF

COPY stream1090-overrides/ /tmp/stream1090-overrides/

RUN set -eux && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      cmake \
      g++ \
      git \
      libairspy-dev \
      libconfig++-dev \
      librtlsdr-dev \
      make \
      pkg-config && \
    rm -rf /var/lib/apt/lists/*

RUN set -eux && \
    git clone --depth 1 --branch "${STREAM1090_REF}" "${STREAM1090_REPO}" /src/stream1090 && \
  cp -a /tmp/stream1090-overrides/. /src/stream1090/ && \
    cmake -S /src/stream1090 -B /tmp/build -DCMAKE_BUILD_TYPE=Release && \
    cmake --build /tmp/build --parallel "$(nproc)" && \
    mkdir -p /tmp/out && \
    install -m 0755 /tmp/build/stream1090 /tmp/out/stream1090 && \
    git -C /src/stream1090 rev-parse HEAD > /tmp/out/STREAM1090_COMMIT

FROM ghcr.io/sdr-enthusiasts/docker-baseimage:base

# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026, Ramon F. Kolb (kx1t) and contributors
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN set -eux && \
    apt-get update && \
    AIRSPY_PKG="$(apt-cache search '^libairspy[0-9]+' | awk '{print $1}' | head -n 1)" && \
    CONFIGPP_PKG="$(apt-cache search '^libconfig\+\+[0-9]+' | awk '{print $1}' | head -n 1)" && \
    if [[ -z "${AIRSPY_PKG}" || -z "${CONFIGPP_PKG}" ]]; then \
      echo "Could not resolve runtime package names for libairspy/libconfig++" >&2; \
      exit 1; \
    fi && \
    apt-get install -y --no-install-recommends \
      "${AIRSPY_PKG}" \
      "${CONFIGPP_PKG}" \
      socat && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/out/stream1090 /usr/local/bin/stream1090
COPY --from=builder /tmp/out/STREAM1090_COMMIT /STREAM1090_COMMIT
COPY rootfs/ /

RUN set -eux && \
        chmod +x \
      /etc/s6-overlay/startup.d/80-stream1090-info \
      /etc/s6-overlay/startup.d/90-stream1090-config \
            /etc/s6-overlay/scripts/stream1090 \
      /etc/s6-overlay/s6-rc.d/stream1090/run \
      /etc/s6-overlay/s6-rc.d/startup/up

ENV STREAM1090_DEVICE=rtlsdr \
    STREAM1090_SERIAL="" \
    STREAM1090_FREQUENCY=1090000000 \
    STREAM1090_BIAS_TEE=false \
    STREAM1090_SAMPLE_RATE="" \
    STREAM1090_UPSAMPLE_RATE="" \
    STREAM1090_ENABLE_IQ_FILTER=false \
    STREAM1090_TAPS_FILE="" \
    STREAM1090_VERBOSE=false \
    STREAM1090_OUTPUT_HOST=0.0.0.0 \
    STREAM1090_OUTPUT_PORT=30001 \
    STREAM1090_RTL_GAIN="" \
    STREAM1090_RTL_AGC=true \
    STREAM1090_RTL_PPM="" \
    STREAM1090_RTL_TUNER_BANDWIDTH="" \
    STREAM1090_RTL_LNA_GAIN="" \
    STREAM1090_RTL_MIXER_GAIN="" \
    STREAM1090_RTL_VGA_GAIN="" \
    STREAM1090_AIRSPY_LINEARITY_GAIN=16 \
    STREAM1090_AIRSPY_SENSITIVITY_GAIN="" \
    STREAM1090_AIRSPY_LNA_GAIN="" \
    STREAM1090_AIRSPY_MIXER_GAIN="" \
    STREAM1090_AIRSPY_VGA_GAIN=""

EXPOSE 30001/tcp
