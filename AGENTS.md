# AGENTS.md

## What this repo is

A build-automation repo that produces `.deb` packages of [INDI](https://www.indilib.org/) core, selected 3rd-party drivers, libXISF, and PHD2 for **NVIDIA Jetson Nano (arm64, Ubuntu 18.04 / bionic)**. There is no application source code here -- the actual source lives in **git submodules**.

## Repository structure

- `indi/`, `indi-3rdparty/`, `libXISF/`, `phd2/` -- git submodules pinned to specific branches/tags (see `.gitmodules`)
- `INDI_VERSION` -- single-line file with the current INDI version (e.g. `2.1.9`).
- `INDI_3RD_PARTY_DRIVERS` -- newline-separated list of 3rd-party driver/lib names to build
- `Dockerfile` -- Ubuntu 18.04 arm64 build environment image (`alxgomz/indi-builder`)
- `entrypoint.sh` -- main build script run inside the Docker container; builds libXISF, INDI core, 3rd-party drivers, and PHD2 as deb packages
- `patches/` -- patches applied to `indi/` source before building (currently `SPC900NC.diff`)
- `kernel/` -- kernel module configs (5.10)

## Build pipeline

Builds run via **GitHub Actions** (`packages-build.yml`, manual `workflow_dispatch` only):

1. Checks out repo with submodules
2. Runs the Docker builder image with `INDI_VERSION` and `INDI_3RD_PARTY_DRIVERS` as env vars
3. Inside container, `entrypoint.sh` builds packages with `dpkg-buildpackage` in order: libXISF -> INDI core -> 3rd-party drivers -> PHD2
4. Resulting `.deb` files are published to an APT repo on the `debs` branch via GitHub Pages

**Build order matters**: each step installs its `.deb` output before the next step can compile against it. Libraries (`lib*`) from the 3rd-party list are installed immediately after building.

## Key commands

There are no local test or lint commands. All building happens inside the Docker container:

```sh
# Build the builder image locally
docker build --platform linux/arm64 -t indi-builder .

# Run a full package build (must be on arm64 or use QEMU)
docker run --rm \
  -e DEB_BUILD_OPTIONS=noautodbgsym \
  -e DEB_BUILD_PROFILES=noautodbgsym \
  -e INDI_VERSION="$(cat INDI_VERSION)" \
  -e INDI_3RD_PARTY_DRIVERS="$(cat INDI_3RD_PARTY_DRIVERS)" \
  -v $PWD:/usr/src/ alxgomz/indi-builder:2.3.0
```

## Gotchas

- **Submodules**: always check out with `--recurse-submodules`. The `indi-3rdparty` submodule points to a **fork** (`alxgomz/indi-3rdparty`, branch `ubuntu-18.04`), not upstream.
- **arm64 only**: the Dockerfile targets `linux/arm64`. CI uses `ubuntu-24.04-arm` runners.
- **Ubuntu 18.04 (bionic)**: the build toolchain is old (gcc-8, cmake 3.31.7 built from source). Packages target bionic.
- **Docker image version** (`DOCKER_TAG: 2.3.0`) is hardcoded in both `docker-build.yml` and `packages-build.yml`. Update both when bumping.
