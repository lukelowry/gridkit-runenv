# syntax=docker/dockerfile:1
#
# GridKit install artifact built by Cloud Build and consumed with COPY --from.
# The final scratch image contains:
#   /opt/suitesparse/lib/    libklu.so*, libsuitesparseconfig.so*, libamd/colamd/btf.so*
#   /opt/sundials/lib/       libsundials_*.so*
#   /opt/gridkit/            installed GridKit prefix with application binaries

ARG UBUNTU_TAG=24.04
ARG LLVM_VERSION=16
ARG CXX_COMPILER_VERSION=13
ARG SUITESPARSE_PREFIX=/opt/suitesparse
ARG SUNDIALS_PREFIX=/opt/sundials
ARG ENZYME_PREFIX=/opt/enzyme
ARG GRIDKIT_PREFIX=/opt/gridkit

# -- SuiteSparse 7.10.2 (KLU) --
FROM ubuntu:${UBUNTU_TAG} AS suitesparse
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git ca-certificates libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*
ARG SUITESPARSE_VERSION=v7.10.2
ARG SUITESPARSE_PREFIX
RUN git clone --depth 1 --branch ${SUITESPARSE_VERSION} \
        https://github.com/DrTimothyAldenDavis/SuiteSparse.git /src/suitesparse
WORKDIR /src/suitesparse/build
RUN cmake .. -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${SUITESPARSE_PREFIX} \
        -DSUITESPARSE_ENABLE_PROJECTS="klu" \
    && ninja install \
    && find ${SUITESPARSE_PREFIX}/lib -name '*.so*' -type f -exec strip --strip-unneeded {} +

# -- SUNDIALS 7.4.0 against SuiteSparse --
FROM ubuntu:${UBUNTU_TAG} AS sundials
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git ca-certificates libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*
ARG SUNDIALS_VERSION=v7.4.0
ARG SUITESPARSE_PREFIX
ARG SUNDIALS_PREFIX
COPY --from=suitesparse ${SUITESPARSE_PREFIX} ${SUITESPARSE_PREFIX}
RUN git clone --depth 1 --branch ${SUNDIALS_VERSION} \
        https://github.com/LLNL/sundials.git /src/sundials
WORKDIR /src/sundials/build
RUN cmake .. -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${SUNDIALS_PREFIX} \
        -DBUILD_SHARED_LIBS=ON -DBUILD_STATIC_LIBS=OFF \
        -DENABLE_KLU=ON \
        -DKLU_INCLUDE_DIR=${SUITESPARSE_PREFIX}/include/suitesparse \
        -DKLU_LIBRARY_DIR=${SUITESPARSE_PREFIX}/lib \
        -DEXAMPLES_ENABLE_C=OFF -DEXAMPLES_ENABLE_CXX=OFF \
    && ninja install \
    && find ${SUNDIALS_PREFIX}/lib -name '*.so*' -type f -exec strip --strip-unneeded {} +

# -- Enzyme against the configured LLVM toolchain (build-only) --
FROM ubuntu:${UBUNTU_TAG} AS enzyme
ARG LLVM_VERSION
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git ca-certificates \
        clang-${LLVM_VERSION} libclang-${LLVM_VERSION}-dev llvm-${LLVM_VERSION}-dev llvm-${LLVM_VERSION}-tools \
        libcurl4-openssl-dev libzstd-dev zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*
ARG ENZYME_VERSION=v0.0.206
ARG ENZYME_PREFIX
RUN git clone --depth 1 --branch ${ENZYME_VERSION} \
        https://github.com/EnzymeAD/Enzyme.git /src/enzyme
WORKDIR /src/enzyme/enzyme/build
ARG ENZYME_BUILD_JOBS=8
RUN cmake .. -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX=${ENZYME_PREFIX} \
        -DLLVM_DIR=/usr/lib/llvm-${LLVM_VERSION}/lib/cmake/llvm \
        -DClang_DIR=/usr/lib/llvm-${LLVM_VERSION}/lib/cmake/clang \
        -DENZYME_CLANG=ON \
    && cmake --build . --parallel ${ENZYME_BUILD_JOBS} \
    && cmake --install . \
    && test -f ${ENZYME_PREFIX}/lib/ClangEnzyme-${LLVM_VERSION}.so \
    && test -f ${ENZYME_PREFIX}/lib/LLVMEnzyme-${LLVM_VERSION}.so

# -- GridKit applications with SUNDIALS + SuiteSparse + Enzyme --
FROM ubuntu:${UBUNTU_TAG} AS gridkit
ARG LLVM_VERSION
ARG CXX_COMPILER_VERSION
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        build-essential cmake ninja-build git ca-certificates \
        clang-${LLVM_VERSION} libclang-${LLVM_VERSION}-dev llvm-${LLVM_VERSION}-dev llvm-${LLVM_VERSION}-tools g++-${CXX_COMPILER_VERSION} \
        libcurl4-openssl-dev libzstd-dev zlib1g-dev libopenblas-dev \
    && rm -rf /var/lib/apt/lists/*
ARG SUITESPARSE_PREFIX
ARG SUNDIALS_PREFIX
ARG ENZYME_PREFIX
ARG GRIDKIT_PREFIX
COPY --from=suitesparse ${SUITESPARSE_PREFIX} ${SUITESPARSE_PREFIX}
COPY --from=sundials    ${SUNDIALS_PREFIX}    ${SUNDIALS_PREFIX}
COPY --from=enzyme      ${ENZYME_PREFIX}      ${ENZYME_PREFIX}
ARG GRIDKIT_REF=develop
RUN git clone https://github.com/ORNL/GridKit.git /src/gridkit \
    && cd /src/gridkit && git checkout ${GRIDKIT_REF} \
    && git submodule update --init third-party/
WORKDIR /src/gridkit/build
ARG GRIDKIT_BUILD_JOBS=24
RUN cmake .. -G Ninja \
        -DCMAKE_C_COMPILER=clang-${LLVM_VERSION} -DCMAKE_CXX_COMPILER=clang++-${LLVM_VERSION} \
        -DCMAKE_BUILD_TYPE=RelWithDebInfo \
        -DCMAKE_INSTALL_PREFIX=${GRIDKIT_PREFIX} \
        -DSUNDIALS_DIR=${SUNDIALS_PREFIX} \
        -DSUITESPARSE_DIR=${SUITESPARSE_PREFIX} \
        -DCMAKE_PREFIX_PATH=${SUITESPARSE_PREFIX} \
        -DENZYME_DIR=${ENZYME_PREFIX} \
        -DEnzyme_LLVM_BINARY_DIR=/usr/lib/llvm-${LLVM_VERSION} \
        -DGridKit_ENABLE_SUNDIALS=ON \
        -DGridKit_ENABLE_IPOPT=OFF \
        -DGridKit_ENABLE_ENZYME=ON \
    && cmake --build . --parallel ${GRIDKIT_BUILD_JOBS} \
    && ctest --output-on-failure \
    && cmake --install . --prefix ${GRIDKIT_PREFIX} \
    && strip --strip-unneeded ${GRIDKIT_PREFIX}/bin/DynamicSimulation ${GRIDKIT_PREFIX}/bin/ContingencyAnalysis \
    && find ${GRIDKIT_PREFIX}/lib -name '*.so*' -type f -exec strip --strip-unneeded {} + \
    && for app in DynamicSimulation ContingencyAnalysis; do \
        if LD_LIBRARY_PATH=${GRIDKIT_PREFIX}/lib:${SUNDIALS_PREFIX}/lib:${SUITESPARSE_PREFIX}/lib \
          ldd ${GRIDKIT_PREFIX}/bin/${app} | grep -q 'not found'; then \
          echo "unresolved deps for ${app}" && exit 1; \
        fi; \
      done

# Record the resolved native toolchain in the artifact.
ARG SUITESPARSE_VERSION=v7.10.2
ARG SUNDIALS_VERSION=v7.4.0
ARG GRIDKIT_PREFIX
RUN <<EOF
set -e
cd /src/gridkit
GRIDKIT_COMMIT=$(git rev-parse HEAD)
BUILT_AT=$(date -u +%Y-%m-%dT%H:%M:%SZ)
mkdir -p ${GRIDKIT_PREFIX}/share/gridkit
cat > ${GRIDKIT_PREFIX}/share/gridkit/toolchain.json <<JSON
{
  "gridkit_commit": "${GRIDKIT_COMMIT}",
  "sundials_version": "${SUNDIALS_VERSION}",
  "suitesparse_version": "${SUITESPARSE_VERSION}",
  "enzyme_enabled": true,
  "image_built_at": "${BUILT_AT}"
}
JSON
EOF

# -- Final: scratch image with runtime artifacts only --
FROM scratch
ARG SUITESPARSE_PREFIX
ARG SUNDIALS_PREFIX
ARG GRIDKIT_PREFIX
ARG SOURCE_REVISION=unknown
COPY --from=suitesparse ${SUITESPARSE_PREFIX}/lib/                   ${SUITESPARSE_PREFIX}/lib/
COPY --from=sundials    ${SUNDIALS_PREFIX}/lib/                      ${SUNDIALS_PREFIX}/lib/
COPY --from=gridkit     ${GRIDKIT_PREFIX}/                           ${GRIDKIT_PREFIX}/
LABEL org.opencontainers.image.title="gridkit-runenv/gridkit-install"
LABEL org.opencontainers.image.description="GridKit applications and native runtime dependencies for COPY --from consumption."
LABEL org.opencontainers.image.source="https://github.com/lukelowry/gridkit-runenv"
LABEL org.opencontainers.image.revision="${SOURCE_REVISION}"
