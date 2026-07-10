# GridKit Studio run environment

This repository is a small, reproducible environment for exercising GridKit cases through the
GridKit Studio VS Code extension. GridKit and its native dependencies are supplied by the dev-container
image; nothing is loaded from the host machine. The dev-container Dockerfile pins the
validated GridKit artifact digest so reopening the environment cannot silently change the
native solver.

## Open it

Prerequisites:

- Docker Desktop or another Docker engine with amd64 container support
- VS Code with the **Dev Containers** extension

Clone the repository, open its folder in VS Code, and run **Dev Containers: Reopen in Container**.
The first build downloads the public GridKit runtime image. When VS Code attaches, it installs the
checked-in `studio-0.1.1.vsix` automatically. The attach hook first removes the legacy
`gridkit.workbench-vscode` identity, because both packages intentionally use the same stable
`workbench.*` commands and views.

The GridKit artifact is currently amd64-only. Apple Silicon and other ARM hosts therefore run this
container through Docker's amd64 emulation.

## Verify the environment

From the container terminal:

```sh
test -x /opt/gridkit/bin/DynamicSimulation
code --list-extensions | grep '^gridkit.studio$'
```

Open either solver file and run the study from GridKit Studio. Generated `*.run/` directories are local
test output and are ignored by Git.
