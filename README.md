<!-- SPDX-License-Identifier: GPL-3.0-or-later -->
<!-- Copyright (C) 2026, Ramon F. Kolb (kx1t) and contributors -->

# docker-stream1090

Containerized [stream1090](https://github.com/mgrone/stream1090) for RTL-SDR and Airspy, built on `ghcr.io/sdr-enthusiasts/docker-baseimage:base`.

The container demodulates Mode-S/ADS-B and exposes RAW frames on a TCP port so decoders (for example Ultrafeeder/readsb) can connect.

## Quick Start (Minimal)

Set only these two environment variables:

- `STREAM1090_DEVICE=rtlsdr` or `STREAM1090_DEVICE=airspy`
- `STREAM1090_SERIAL=<your SDR serial>`

Set `STREAM1090_VERBOSE=true` if you want stream1090 to run with `-v` and emit verbose output.

Then start the container with USB pass-through:

```bash
docker compose up -d
```

The output stream is available on port `30001/tcp` by default.

## Ultrafeeder Connection

Use this in your Ultrafeeder environment:

```text
ULTRAFEEDER_CONFIG=adsb,stream1090,30001,raw_in
```

If both containers are in the same compose project/network, `stream1090` is the service name.

## Runtime Variables

### Required minimum

- `STREAM1090_DEVICE`: `rtlsdr` or `airspy`
- `STREAM1090_SERIAL`: SDR serial number

### General options

- `STREAM1090_SAMPLE_RATE`: Input sample rate in MHz. Defaults by device:
  - `2.4` for RTL-SDR
  - `6` for Airspy
- `STREAM1090_UPSAMPLE_RATE`: Optional upsample rate in MHz (`-u`)
- `STREAM1090_ENABLE_IQ_FILTER`: `true/false` to enable `-q` IQ FIR filter
- `STREAM1090_TAPS_FILE`: Optional taps file path (`-f`)
- `STREAM1090_VERBOSE`: `true/false` for verbose mode (`-v`)
- `STREAM1090_OUTPUT_HOST`: TCP bind host (default: `0.0.0.0`)
- `STREAM1090_OUTPUT_PORT`: TCP output port (default: `30001`)

### Shared device options

- `STREAM1090_FREQUENCY`: Center frequency in Hz (default: `1090000000`)
- `STREAM1090_BIAS_TEE`: `true/false` (default: `false`)

### RTL-SDR options

- `STREAM1090_RTL_GAIN`
- `STREAM1090_RTL_AGC` (default: `true`)
- `STREAM1090_RTL_PPM`
- `STREAM1090_RTL_TUNER_BANDWIDTH`
- `STREAM1090_RTL_LNA_GAIN`
- `STREAM1090_RTL_MIXER_GAIN`
- `STREAM1090_RTL_VGA_GAIN`

### Airspy options

- `STREAM1090_AIRSPY_LINEARITY_GAIN` (default: `16`)
- `STREAM1090_AIRSPY_SENSITIVITY_GAIN`
- `STREAM1090_AIRSPY_LNA_GAIN`
- `STREAM1090_AIRSPY_MIXER_GAIN`
- `STREAM1090_AIRSPY_VGA_GAIN`

## Notes

- Defaults and option behavior follow upstream stream1090 defaults from:
  - `configs/rtlsdr.ini`
  - `configs/airspy.ini`
  - stream1090 command line options (`-s`, `-u`, `-d`, `-q`, `-f`, `-v`)
- This repository is licensed under GPLv3. See [LICENSE](LICENSE).
