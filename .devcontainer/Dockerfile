# syntax=docker/dockerfile:1

# The local build workflow publishes gridkit-install for linux/amd64.
ARG GRIDKIT_INSTALL_IMAGE=us-central1-docker.pkg.dev/gridkitvm/lattice/gridkit-install@sha256:a84fdd24977f8c3b1ce5fba39ca13c68f0370c177f8c7592dc3d48e4a812c829
ARG RUNTIME_PLATFORM=linux/amd64

FROM --platform=${RUNTIME_PLATFORM} ${GRIDKIT_INSTALL_IMAGE} AS gridkit

FROM --platform=${RUNTIME_PLATFORM} mcr.microsoft.com/devcontainers/base:1-ubuntu-24.04@sha256:763eca1839b2c6366f25b9c2b4c75c46e3d485a8d1b95f725e829397398a4c46

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        libgomp1 \
        libopenblas0 \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=gridkit /opt/suitesparse/ /opt/suitesparse/
COPY --from=gridkit /opt/sundials/ /opt/sundials/
COPY --from=gridkit /opt/gridkit/ /opt/gridkit/

RUN <<'EOF'
set -eu

printf '%s\n' \
    /opt/suitesparse/lib \
    /opt/sundials/lib \
    /opt/gridkit/lib \
    > /etc/ld.so.conf.d/gridkit.conf

ldconfig

app=/opt/gridkit/bin/DynamicSimulation

if [ ! -x "$app" ]; then
    echo "GridKit executable is missing or not executable: $app" >&2
    exit 1
fi

dependencies="$(ldd "$app")"

case "$dependencies" in
    *"not found"*)
        echo "Unresolved GridKit runtime dependencies:" >&2
        printf '%s\n' "$dependencies" >&2
        exit 1
        ;;
esac
EOF
