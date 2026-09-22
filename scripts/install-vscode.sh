#!/usr/bin/env bash
#
# Install the VS Code extensions listed in vscode/extensions.txt.
#
# The settings file is not installed here. mise copies it as a dotfile.
#
# The "code" command comes from VS Code on Windows. It exists only after
# VS Code connects to this WSL instance one time. If it is missing, this
# script does nothing and says so.
#
set -euo pipefail

STAGE="VSCODE"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

REPO_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
EXTENSIONS="${REPO_ROOT}/vscode/extensions.txt"

stage "Extensions"

if ! command -v code >/dev/null 2>&1; then
    info "the 'code' command is not available yet"
    info "connect VS Code to this WSL instance, then run:"
    info "    ${BASH_SOURCE[0]}"
    exit 0
fi

# Ask VS Code once for the list it already has. Asking for each extension
# is slow, because every call starts the whole server.
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
    # Remove comments and empty lines.
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
