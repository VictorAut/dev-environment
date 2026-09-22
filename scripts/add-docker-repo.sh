#!/usr/bin/env bash
#
# Add the Docker package repository.
#
# mise installs the docker packages from [bootstrap.packages]. But apt
# cannot find them until this repository is added. So this script runs in
# the "pre-packages" phase, before apt installs anything.
#
# The script downloads the signing key. It does not keep a copy in this
# repository, because Docker replaces the key from time to time.
#
set -euo pipefail

STAGE="DOCKER"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

KEYRING="/etc/apt/keyrings/docker.asc"
LIST="/etc/apt/sources.list.d/docker.list"

stage "Package repository"

if [[ -f "${KEYRING}" && -f "${LIST}" ]]; then
    info "already added"
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

info "added for ${codename} (${arch})"
