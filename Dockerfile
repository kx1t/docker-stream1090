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
    apt-get install -y --no-install-recommends \
      libairspy0 \
      libconfig++9v5 \
      socat && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /tmp/out/stream1090 /usr/local/bin/stream1090
COPY --from=builder /tmp/out/STREAM1090_COMMIT /STREAM1090_COMMIT
COPY rootfs/ /

RUN set -eux && \
        chmod +x \
            /etc/s6-overlay/startup.d/10-stream1090-config \
            /etc/s6-overlay/scripts/stream1090 \
            /etc/s6-overlay/s6-rc.d/stream1090/run

ENV STREAM1090_DEVICE=rtlsdr
ENV STREAM1090_SERIAL=
ENV STREAM1090_FREQUENCY=1090000000
ENV STREAM1090_BIAS_TEE=false
ENV STREAM1090_SAMPLE_RATE=
ENV STREAM1090_UPSAMPLE_RATE=
ENV STREAM1090_ENABLE_IQ_FILTER=false
ENV STREAM1090_TAPS_FILE=
ENV STREAM1090_VERBOSE=false
ENV STREAM1090_OUTPUT_HOST=0.0.0.0
ENV STREAM1090_OUTPUT_PORT=30001
ENV STREAM1090_RTL_GAIN=
ENV STREAM1090_RTL_AGC=true
ENV STREAM1090_RTL_PPM=
ENV STREAM1090_RTL_TUNER_BANDWIDTH=
ENV STREAM1090_RTL_LNA_GAIN=
ENV STREAM1090_RTL_MIXER_GAIN=
ENV STREAM1090_RTL_VGA_GAIN=
ENV STREAM1090_AIRSPY_LINEARITY_GAIN=16
ENV STREAM1090_AIRSPY_SENSITIVITY_GAIN=
ENV STREAM1090_AIRSPY_LNA_GAIN=
ENV STREAM1090_AIRSPY_MIXER_GAIN=
ENV STREAM1090_AIRSPY_VGA_GAIN=

EXPOSE 30001/tcp
