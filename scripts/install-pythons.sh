#!/usr/bin/env bash
#
# Install every stable CPython from MIN_MINOR up to the latest stable release.
#
# The version list is discovered at runtime from uv, so nothing here needs
# editing when a new Python is released.
#
set -euo pipefail

MIN_MINOR=10

if ! command -v uv >/dev/null 2>&1; then
    echo "error: uv is not on PATH. Run bootstrap.sh first." >&2
    exit 1
fi

echo "==> Discovering available Python versions"

# uv prints one line per build, for example:
#   cpython-3.13.7-linux-x86_64-gnu                 <download available>
#   cpython-3.15.0a1-linux-x86_64-gnu               <download available>
#   cpython-3.13.7+freethreaded-linux-x86_64-gnu    <download available>
#
# The pattern below requires digits-dot-digits-dot-digits followed by "-", so
# pre-releases (3.15.0a1) and variant builds (+freethreaded) are dropped.
mapfile -t minors < <(
    uv python list --all-versions \
        | grep -oE '(^|[[:space:]])cpython-3\.[0-9]+\.[0-9]+-' \
        | grep -oE '3\.[0-9]+' \
        | sort -u -t. -k2,2n
)

if [[ ${#minors[@]} -eq 0 ]]; then
    echo "error: could not parse any Python versions from 'uv python list'." >&2
    echo "       Run it by hand to see what changed." >&2
    exit 1
fi

wanted=()

for minor in "${minors[@]}"; do
    if [[ ${minor#3.} -ge ${MIN_MINOR} ]]; then
        wanted+=("${minor}")
    fi
done

if [[ ${#wanted[@]} -eq 0 ]]; then
    echo "error: no Python >= 3.${MIN_MINOR} available." >&2
    exit 1
fi

latest="${wanted[-1]}"

echo "    Stable versions: ${wanted[*]}"
echo "    Latest stable:   ${latest}"

echo
echo "==> Installing"

# Already-installed versions are skipped by uv, so this is safe to re-run.
uv python install "${wanted[@]}"

echo
echo "==> Setting Python ${latest} as the default 'python' on PATH"

if ! uv python install --default --preview "${latest}"; then
    echo "note: could not install the default 'python' shim."
    echo "      Not fatal - use 'uv run' or a project virtualenv instead."
fi

echo
echo "==> Python installation complete"
