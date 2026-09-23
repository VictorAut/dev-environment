#!/usr/bin/env bash
#
# Install every stable CPython from MIN_MINOR up to the newest stable one.
#
# The list comes from uv while the script runs. Nothing here needs an edit
# when a new Python comes out.
#
set -euo pipefail

STAGE="PYTHON"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

MIN_MINOR=10

if ! command -v uv >/dev/null 2>&1; then
    fail "uv is not on PATH. Run the bootstrap first."
    exit 1
fi

stage "Finding the available versions"

# uv prints one line for each build:
#   cpython-3.13.7-linux-x86_64-gnu                 <download available>
#   cpython-3.15.0a1-linux-x86_64-gnu               <download available>
#   cpython-3.13.7+freethreaded-linux-x86_64-gnu    <download available>
#
# The pattern needs digits.digits.digits and then "-". So it drops test
# releases (3.15.0a1) and special builds (+freethreaded).
mapfile -t minors < <(
    uv python list --all-versions \
        | grep -oE '(^|[[:space:]])cpython-3\.[0-9]+\.[0-9]+-' \
        | grep -oE '3\.[0-9]+' \
        | sort -u -t. -k2,2n
)

if [[ ${#minors[@]} -eq 0 ]]; then
    fail "found no Python version in the output of 'uv python list'."
    fail "run that command by hand to see what changed."
    exit 1
fi

wanted=()

for minor in "${minors[@]}"; do
    if [[ ${minor#3.} -ge ${MIN_MINOR} ]]; then
        wanted+=("${minor}")
    fi
done

if [[ ${#wanted[@]} -eq 0 ]]; then
    fail "no Python 3.${MIN_MINOR} or newer is available."
    exit 1
fi

latest="${wanted[-1]}"

info "stable versions: ${wanted[*]}"
info "newest stable:   ${latest}"

stage "Installing"

# uv skips a version it already has, so this is safe to run again.
uv python install "${wanted[@]}"

stage "Making Python ${latest} the default"

if uv python install --default "${latest}"; then
    info "the 'python' command now runs ${latest}"
else
    warn "could not install the default 'python' command."
    warn "this is not serious. Use 'uv run' or a project instead."
fi
