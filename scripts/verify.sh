#!/usr/bin/env bash

set -euo pipefail

echo "==> Verifying development environment"
echo

echo "mise:"
mise --version

echo
echo "uv:"
uv --version

echo
echo "Python:"
python --version

echo
echo "Installed Python versions:"
mise ls python

echo
echo "Python executables:"

for version in 3.10 3.11 3.12 3.13 3.14 3.15; do
    printf "  %-6s " "${version}"

    mise exec "python@${version}" -- python --version
done

echo
echo "==> All checks passed"