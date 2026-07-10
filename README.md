# GridKit Studio run environment

This repository provides a reproducible development environment for exercising
GridKit cases through the GridKit Studio VS Code extension. GridKit and its native
dependencies come from a pinned install-artifact image; nothing is loaded from the
host machine.

## Open the environment

Requirements:

- Docker Desktop or another Docker engine with AMD64 container support
- VS Code with the **Dev Containers** extension

Clone the repository, open its folder in VS Code, and run **Dev Containers: Reopen
in Container**. The dev container copies the GridKit installation from the image
digest pinned in `.devcontainer/Dockerfile`. When VS Code attaches, the setup script
installs the single checked-in `studio-*.vsix` package.

The GridKit artifact is currently AMD64-only. Apple Silicon and other ARM hosts run
the container through Docker's AMD64 emulation.

## Verify the environment

From the container terminal:

```sh
test -x /opt/gridkit/bin/DynamicSimulation
code --list-extensions | grep '^gridkit.studio$'
```

Open a compatible solver file and run its study from GridKit Studio. Generated
`*.run/` directories are local test output and are ignored by Git.

## GridKit install image

This repository owns the build definition for the install-artifact image consumed by
the dev container:

```text
us-central1-docker.pkg.dev/gridkitvm/lattice/gridkit-install
```

The final image is based on `scratch` and is not a runnable container. It contains
the installed GridKit prefix and native libraries for use with Docker
`COPY --from`.

The default GridKit source revision is pinned in `docker/Dockerfile`. Relevant changes
on `main` trigger
`.github/workflows/build.yml`, which authenticates to Google Cloud through Workload
Identity Federation and submits `docker/cloudbuild.yaml`.

The destination GitHub repository must define these Actions variables:

- `GCP_WIF_PROVIDER`
- `GCP_DEPLOYER_SA`

The corresponding Google Cloud identity binding must authorize
`lukelowry/gridkit-runenv` to submit builds. The Cloud Build service account must be
able to publish to the `gridkitvm/lattice` Artifact Registry repository.

To submit the same build manually:

```sh
gcloud builds submit \
  --project=gridkitvm \
  --config=docker/cloudbuild.yaml \
  .
```

After validating a new image, update `.devcontainer/Dockerfile` to its immutable
digest. Do not replace the digest pin with `latest`.
