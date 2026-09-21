#!/usr/bin/env bash
#
# Set up a fresh Ubuntu WSL environment.
#
# Almost everything is declared in mise.toml. This script only installs
# mise, then asks mise to apply that configuration.
#
# You do not need this script if you start from the network:
#
#     curl -fsSL https://mise.run | sh
#     ~/.local/bin/mise bootstrap --from <this repository url> --force-dotfiles
#
# Use this script when you have already cloned the repository.
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MISE_BIN="${HOME}/.local/bin/mise"

export PATH="${HOME}/.local/bin:${PATH}"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Do not run this script as root. It uses sudo when it needs to." >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script needs a Debian or Ubuntu system." >&2
    exit 1
fi

echo "==> Checking sudo access"
sudo -v

echo
echo "==> Installing mise"

if [[ -x "${MISE_BIN}" ]]; then
    echo "    Already installed."
else
    # -f makes curl fail on an HTTP error. Without it, an error page would
    # be piped into the shell.
    curl -fsSL https://mise.run | sh
fi

"${MISE_BIN}" --version

echo
echo "==> Applying mise.toml"

cd -- "${REPO_ROOT}"
"${MISE_BIN}" trust --yes

# --force-dotfiles replaces the stock ~/.bashrc that Ubuntu ships. Without
# it, mise stops rather than overwrite a file it does not own.
"${MISE_BIN}" bootstrap --yes --force-dotfiles "$@"

echo
echo "==> Bootstrap complete"
echo
echo "    Open a new shell."
echo "    Then run 'wsl --shutdown' in Windows PowerShell, for Docker."
