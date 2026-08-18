# Image build

`Dockerfile` builds GridKit's `develop` branch and publishes two targets
through `cloudbuild.yaml`:

- `install` — scratch artifact image (`gridkit-install`), consumed with
  `COPY --from` by the dev container. Not runnable.
- `runtime` — runnable image (`gridkit`) with the applications on `PATH`,
  `WORKDIR /work`, and entrypoint `DynamicSimulation`.

The build smoke-tests the runtime image against the fixture in `smoke/`
(a frozen copy of the TwoArea case plus a short study) before any push.
Every build publishes the moving `latest` tags and an immutable
`gridkit:YYYYMMDD-HHMMSS` tag.

Manual submission, from the repository root:

```sh
gcloud builds submit --project=gridkitvm --config=docker/cloudbuild.yaml .
```
