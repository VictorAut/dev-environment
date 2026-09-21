#!/usr/bin/env bash

set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MISE_BIN="${HOME}/.local/bin/mise"

echo "==> Bootstrapping development environment"
echo "    Repository: ${REPO_ROOT}"

echo
echo "==> Installing base system dependencies"

sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    git \
    build-essential

echo
echo "==> Installing mise"

if [[ ! -x "${MISE_BIN}" ]]; then
    curl https://mise.run | sh
else
    echo "mise is already installed"
fi

export PATH="${HOME}/.local/bin:${PATH}"

echo
echo "==> mise version"
mise --version

echo
echo "==> Trusting repository configuration"

cd "${REPO_ROOT}"
mise trust

echo
echo "==> Running mise bootstrap"

mise bootstrap --yes

echo
echo "==> Bootstrap complete"
echo
echo "Open a new shell before continuing."