#!/usr/bin/env bash
#
# Set up a fresh Ubuntu WSL environment.
#
# Almost everything is declared in mise.toml. This script installs mise,
# then asks mise to apply that file.
#
# You do not need this script if you start from the network:
#
#     curl -fsSL https://mise.run | sh
#     ~/.local/bin/mise bootstrap --from <repository url> --yes --force-dotfiles
#
# Use this script when you already cloned the repository.
#
set -euo pipefail

STAGE="BOOTSTRAP"
# shellcheck source=scripts/lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/scripts/lib.sh"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MISE_BIN="${HOME}/.local/bin/mise"

if [[ "${EUID}" -eq 0 ]]; then
    echo "Do not run this script as root. It uses sudo when it needs to." >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script needs a Debian or Ubuntu system." >&2
    exit 1
fi

stage "Checking sudo access"

sudo -v
info "ok"

stage "Installing mise"

if [[ -x "${MISE_BIN}" ]]; then
    info "already installed"
else
    # -f makes curl stop on an HTTP error. Without it, an error page goes
    # into the shell.
    curl -fsSL https://mise.run | sh
fi

info "$("${MISE_BIN}" --version)"

stage "Applying mise.toml"

cd -- "${REPO_ROOT}"
"${MISE_BIN}" trust --yes

# --yes answers every question with yes, so the setup does not stop.
# --force-dotfiles lets mise replace the ~/.bashrc that Ubuntu ships.
# Without it, mise stops rather than change a file it does not own.
"${MISE_BIN}" bootstrap --yes --force-dotfiles "$@"

stage "Finished"

info "open a new shell"
info "then run 'wsl --shutdown' in Windows PowerShell, for Docker"
