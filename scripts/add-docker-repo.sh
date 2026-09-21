#!/usr/bin/env bash
#
# Add the Docker package repository.
#
# mise installs the docker packages itself, from [bootstrap.packages]. But
# apt cannot find them until this repository is added, so this script runs
# in the "pre-packages" phase.
#
# The GPG key is downloaded instead of stored in this repository, because
# Docker replaces the key from time to time.
#
set -euo pipefail

KEYRING="/etc/apt/keyrings/docker.asc"
LIST="/etc/apt/sources.list.d/docker.list"

echo "==> Docker package repository"

if [[ -f "${KEYRING}" && -f "${LIST}" ]]; then
    echo "    Already added."
    exit 0
fi

# shellcheck source=/dev/null
codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"
arch="$(dpkg --print-architecture)"

sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${KEYRING}"
sudo chmod a+r "${KEYRING}"

echo "deb [arch=${arch} signed-by=${KEYRING}] \
https://download.docker.com/linux/ubuntu ${codename} stable" \
    | sudo tee "${LIST}" >/dev/null

sudo apt-get update

echo "    Added for ${codename} (${arch})."
