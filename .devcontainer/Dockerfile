# syntax=docker/dockerfile:1

ARG GRIDKIT_INSTALL_IMAGE=us-central1-docker.pkg.dev/gridkitvm/lattice/gridkit-install:latest
FROM ${GRIDKIT_INSTALL_IMAGE} AS gridkit-install

FROM mcr.microsoft.com/devcontainers/base:1-ubuntu-24.04

ARG SUITESPARSE_PREFIX=/opt/suitesparse
ARG SUNDIALS_PREFIX=/opt/sundials
ARG GRIDKIT_PREFIX=/opt/gridkit

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        libgomp1 \
        libopenblas0 \
        libstdc++6 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=gridkit-install /opt/suitesparse ${SUITESPARSE_PREFIX}
COPY --from=gridkit-install /opt/sundials ${SUNDIALS_PREFIX}
COPY --from=gridkit-install /opt/gridkit ${GRIDKIT_PREFIX}

ENV SUITESPARSE_PREFIX=${SUITESPARSE_PREFIX}
ENV SUNDIALS_PREFIX=${SUNDIALS_PREFIX}
ENV GRIDKIT_PREFIX=${GRIDKIT_PREFIX}
ENV LD_LIBRARY_PATH=${GRIDKIT_PREFIX}/lib:${SUNDIALS_PREFIX}/lib:${SUITESPARSE_PREFIX}/lib

RUN printf '%s\n' "${SUITESPARSE_PREFIX}/lib" "${SUNDIALS_PREFIX}/lib" "${GRIDKIT_PREFIX}/lib" > /etc/ld.so.conf.d/gridkit.conf \
    && ldconfig \
    && test -d "${GRIDKIT_PREFIX}/bin" \
    && found_app=0 \
    && for app in "${GRIDKIT_PREFIX}"/bin/*; do \
        if [ ! -f "${app}" ] || [ ! -x "${app}" ]; then \
          continue; \
        fi; \
        found_app=1; \
        if ldd "${app}" 2>/dev/null | grep -q 'not found'; then \
          echo "unresolved GridKit runtime dependencies for ${app}" >&2; \
          exit 1; \
        fi; \
      done \
    && test "${found_app}" = "1"
