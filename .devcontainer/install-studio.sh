#!/usr/bin/env bash
set -euo pipefail

workspace=${1:?container workspace path is required}
shopt -s nullglob
studio_packages=("${workspace}"/studio-*.vsix)

if (( ${#studio_packages[@]} != 1 )); then
  echo "Expected exactly one studio-*.vsix in ${workspace}; found ${#studio_packages[@]}." >&2
  exit 1
fi
studio_vsix=${studio_packages[0]}

cli=''
if command -v code >/dev/null 2>&1 && code --version >/dev/null 2>&1; then
  cli=$(command -v code)
else
  # Detached containers have no remote-cli socket, but the standalone server CLI
  # can still update the same extension registry safely.
  for candidate in /vscode/vscode-server/bin/*/*/bin/code-server; do
    if [[ -x "${candidate}" ]]; then
      cli=${candidate}
    fi
  done
fi

if [[ -z "${cli}" ]]; then
  echo "GridKit Studio install skipped: no VS Code extension CLI is available." >&2
  exit 0
fi

# The renamed extension has a new identity but intentionally retains its workbench.*
# contribution IDs. Never leave both packages installed in the remote extension host.
if "${cli}" --list-extensions | grep -Fqx 'gridkit.workbench-vscode'; then
  "${cli}" --uninstall-extension gridkit.workbench-vscode
fi

"${cli}" --install-extension "${studio_vsix}" --force
