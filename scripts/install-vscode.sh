#!/usr/bin/env bash
#
# Set up VS Code inside WSL.
#
# VS Code runs on Windows. It installs a server in WSL, in ~/.vscode-server.
# The settings and extensions of that server belong to this Linux machine,
# so the bootstrap can install them.
#
# The "code" command comes from the Windows installation. It exists only
# after VS Code connects to this WSL instance one time. If it is missing,
# this script installs the settings and skips the extensions.
#
set -euo pipefail

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
MACHINE_DIR="${HOME}/.vscode-server/data/Machine"
TARGET="${MACHINE_DIR}/settings.json"
SOURCE="${REPO_ROOT}/vscode/settings.json"
EXTENSIONS="${REPO_ROOT}/vscode/extensions.txt"

echo "==> VS Code settings"

mkdir -p -- "${MACHINE_DIR}"

if [[ -f "${TARGET}" ]] && cmp -s -- "${SOURCE}" "${TARGET}"; then
    echo "    Already up to date."
else
    if [[ -e "${TARGET}" ]]; then
        backup="${TARGET}.backup.$(date +%Y%m%d%H%M%S)"
        echo "    Old file moved to ${backup}"
        mv -- "${TARGET}" "${backup}"
    fi

    cp -- "${SOURCE}" "${TARGET}"
    echo "    Installed ${TARGET}"
fi

echo
echo "==> VS Code extensions"

if ! command -v code >/dev/null 2>&1; then
    echo "    The 'code' command is not available yet."
    echo "    Connect VS Code to this WSL instance first, then run:"
    echo "        ${BASH_SOURCE[0]}"
    exit 0
fi

# Ask VS Code once which extensions it already has. Asking for each one is
# slow, because every call starts the whole server.
mapfile -t installed < <(code --list-extensions 2>/dev/null | tr '[:upper:]' '[:lower:]')

is_installed() {
    local wanted="${1,,}"
    local have

    for have in ${installed[@]+"${installed[@]}"}; do
        [[ "${have}" == "${wanted}" ]] && return 0
    done

    return 1
}

while read -r extension; do
    # Drop comments and empty lines.
    extension="${extension%%#*}"
    extension="${extension// /}"

    [[ -z "${extension}" ]] && continue

    if is_installed "${extension}"; then
        printf '    have    %s\n' "${extension}"
    elif code --install-extension "${extension}" --force >/dev/null 2>&1; then
        printf '    added   %s\n' "${extension}"
    else
        printf '    FAILED  %s\n' "${extension}"
    fi
done < "${EXTENSIONS}"

echo
echo "==> VS Code setup complete"
