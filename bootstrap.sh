#!/usr/bin/env bash
#
# Set up a fresh Ubuntu WSL environment.
#
# Run this once after you create the WSL instance:
#
#     ./bootstrap.sh
#
# The script is safe to run again. Each step checks its own result first.
# You do not need this repository after the script finishes.
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MISE_BIN="${HOME}/.local/bin/mise"

# Command line tools that mise installs.
# Note: "lts" tracks the newest long-term Node release. Odd-numbered Node
# versions never become long-term releases.
# Python is not here. uv installs Python. See scripts/install-pythons.sh.
TOOLS=(
    uv@latest
    gh@latest
    node@lts
)

# System packages that apt installs.
#
# Note: gh is not here. mise installs it. Two copies of gh would keep two
# separate logins, and the git credential helper points at only one of them.
PACKAGES=(
    # Base
    ca-certificates
    curl
    git
    unzip
    vim

    # Compilers. Some Python packages build from source during installation.
    build-essential
    pkg-config

    # Libraries that common Python packages need in order to build.
    libssl-dev
    libffi-dev
    zlib1g-dev
    libsqlite3-dev
    libxml2-dev
    libxslt1-dev
    libxmlsec1-dev
)

export DEBIAN_FRONTEND=noninteractive
export PATH="${HOME}/.local/bin:${PATH}"

interactive() { [[ -t 0 ]]; }

step() {
    echo
    echo "==> $1"
}

trap 'echo; echo "Bootstrap failed on line ${LINENO}." >&2' ERR

# ---------------------------------------------------------------------------
# Checks
#
# Stop early if the machine is wrong. A late failure wastes several minutes.
# ---------------------------------------------------------------------------

if [[ "${EUID}" -eq 0 ]]; then
    echo "Do not run this script as root. It uses sudo when it needs to." >&2
    exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
    echo "This script needs a Debian or Ubuntu system." >&2
    exit 1
fi

echo "==> Bootstrapping the development environment"
echo "    Repository: ${REPO_ROOT}"

step "Checking sudo access"
sudo -v

# ---------------------------------------------------------------------------
# System packages
# ---------------------------------------------------------------------------

step "Installing system packages"

sudo apt-get update
sudo apt-get install -y --no-install-recommends "${PACKAGES[@]}"

# ---------------------------------------------------------------------------
# mise
# ---------------------------------------------------------------------------

step "Installing mise"

if [[ -x "${MISE_BIN}" ]]; then
    echo "    Already installed."
else
    # -f makes curl fail on an HTTP error. Without it, an error page would
    # be piped into the shell.
    curl -fsSL https://mise.run | sh
fi

"${MISE_BIN}" --version

step "Installing command line tools"

# --global writes ~/.config/mise/config.toml. The tools then work in every
# directory, and they keep working after you delete this repository.
"${MISE_BIN}" use --global --yes "${TOOLS[@]}"

# Put the tools on PATH for the rest of this script.
eval "$("${MISE_BIN}" activate bash --shims)"

# ---------------------------------------------------------------------------
# Workspace
#
# Create these before the git setup. The git identity rules point at them.
# ---------------------------------------------------------------------------

step "Creating workspace directories"

mkdir -p -- "${HOME}/work" "${HOME}/personal"

# ---------------------------------------------------------------------------
# Shell, Python, editor
# ---------------------------------------------------------------------------

step "Setting up the shell"
"${REPO_ROOT}/scripts/install-shell.sh"

step "Installing Python versions"
"${REPO_ROOT}/scripts/install-pythons.sh"

step "Setting up VS Code"
"${REPO_ROOT}/scripts/install-vscode.sh"

step "Installing Docker"
"${REPO_ROOT}/scripts/install-docker.sh"

# ---------------------------------------------------------------------------
# Git and GitHub
# ---------------------------------------------------------------------------

step "Setting up git"
"${REPO_ROOT}/scripts/setup-git.sh"

step "Setting up GitHub access"
"${REPO_ROOT}/scripts/setup-ssh.sh"

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

step "Verifying the result"

"${REPO_ROOT}/scripts/verify.sh"

# ---------------------------------------------------------------------------
# Clean up
# ---------------------------------------------------------------------------

trap - ERR

echo
echo "==> Bootstrap complete"
echo
echo "    Open a new shell to use the new environment."

if interactive; then
    echo
    echo "    This repository is not needed any more. Everything it installed"
    echo "    is now in your home directory."
    echo

    read -r -p "    Delete ${REPO_ROOT}? [y/N] " answer

    if [[ "${answer}" =~ ^[Yy]$ ]]; then
        cd -- "${HOME}"
        rm -rf -- "${REPO_ROOT}"
        echo "    Deleted."
    fi
fi
