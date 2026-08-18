# GridKit run environment

Runnable GridKit container image, the dev container used by GridKit Studio,
and the Cloud Build definition that publishes both. GridKit is never
installed on the host — every simulation runs in a container.

## Setup (once)

- Docker Desktop or another engine with AMD64 support (ARM hosts emulate).
- Registry auth: `gcloud auth configure-docker us-central1-docker.pkg.dev`
- Dev container only: VS Code with the **Dev Containers** extension.

## Run a simulation

From a host terminal at the repo root:

```powershell
docker run --rm --init -v "${PWD}:/work" `
  us-central1-docker.pkg.dev/gridkitvm/lattice/gridkit:latest my.solver.json
```

The checkout is mounted at `/work`; results are written back into it
(`*.run/` output is git-ignored). For contingency analysis add
`--entrypoint ContingencyAnalysis`.

`latest` tracks GridKit `develop` — refresh with `docker pull`. For a
reproducible study, replace `latest` with a CI-published date tag
(`gridkit:YYYYMMDD-HHMMSS`).

## Study files

Minimal `my.solver.json`, kept at the repo root so its case path resolves
under `/work`:

```json
{
  "system_model_file": "cases/TwoArea.case.json",
  "tmax": 4,
  "dt_monitor": 0.004,
  "events": [
    { "time": 1, "type": "fault_on", "element_id": 0 },
    { "time": 1.05, "type": "fault_off", "element_id": 0 }
  ]
}
```

`tmax`, `system_model_file`, and `events` (may be empty) are required.
`dt_monitor` is the output sampling interval; `0` records only each
segment's final value.

## Dev container

VS Code → **Dev Containers: Reopen in Container**. Inside the container
terminal the binaries are on `PATH`:

```sh
DynamicSimulation my.solver.json
```

GridKit Studio uses the same `/opt/gridkit` installation.

## Images and CI

| Image | Role |
| --- | --- |
| `…/lattice/gridkit` | Runnable. Entrypoint `DynamicSimulation`, `WORKDIR /work`. |
| `…/lattice/gridkit-install` | Internal `scratch` artifact the dev container copies from. Not runnable. |

Both build from [docker/Dockerfile](docker/Dockerfile) via
[docker/cloudbuild.yaml](docker/cloudbuild.yaml); a smoke simulation against
[docker/smoke/](docker/smoke/) gates every push. Pushes to `main` touching
`docker/**` trigger [.github/workflows/build.yml](.github/workflows/build.yml)
(requires Actions variables `GCP_WIF_PROVIDER` and `GCP_DEPLOYER_SA`).
Manual build:

```sh
gcloud builds submit --project=gridkitvm --config=docker/cloudbuild.yaml .
```
