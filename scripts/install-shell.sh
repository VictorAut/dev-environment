#!/usr/bin/env bash
#
# Install oh-my-bash. Copy the managed .bashrc into the home directory.
#
# This script clones oh-my-bash directly. It does not use the oh-my-bash
# install.sh, because that installer replaces ~/.bashrc with its own template.
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
OSH_DIR="${HOME}/.oh-my-bash"
SOURCE_BASHRC="${REPO_ROOT}/shell/bashrc"
TARGET="${HOME}/.bashrc"

echo "==> Installing oh-my-bash"

if [[ -d "${OSH_DIR}/.git" ]]; then
    echo "    Already installed. Updating."
    git -C "${OSH_DIR}" pull --ff-only --quiet
else
    git clone --depth=1 https://github.com/ohmybash/oh-my-bash.git "${OSH_DIR}"
fi

echo
echo "==> Installing ${TARGET}"

if [[ -f "${TARGET}" ]] && cmp -s -- "${SOURCE_BASHRC}" "${TARGET}"; then
    echo "    Already up to date."
else
    # Keep the old file. The user may have local changes in it.
    if [[ -e "${TARGET}" || -L "${TARGET}" ]]; then
        backup="${TARGET}.backup.$(date +%Y%m%d%H%M%S)"
        echo "    Old file moved to ${backup}"
        mv -- "${TARGET}" "${backup}"
    fi

    cp -- "${SOURCE_BASHRC}" "${TARGET}"
    echo "    Copied from ${SOURCE_BASHRC}"
fi

echo
echo "==> Shell setup complete"
