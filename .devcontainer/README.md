# GridKit Runtime Dev Container

Pull the GridKit install image before rebuilding the dev container:

```sh
docker pull us-central1-docker.pkg.dev/gridkitvm/lattice/gridkit-install:latest
```

The container copies GridKit from that image into `/opt/gridkit`, which matches
the workspace `gridkit.installPrefix` setting.
