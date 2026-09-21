#!/usr/bin/env bash
#
# Install Docker Engine inside WSL.
#
# Two extra steps are needed in WSL:
#
#   1. systemd must be enabled in /etc/wsl.conf. Without it, the docker
#      service does not start by itself.
#   2. Your user must join the "docker" group. Without it, every command
#      needs sudo.
#
# Both need a full WSL restart from Windows:
#
#      wsl --shutdown
#
# Note: a member of the "docker" group can start a container as root. This
# is the same as giving that user root access on this machine.
#
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

KEYRING="/etc/apt/keyrings/docker.asc"
LIST="/etc/apt/sources.list.d/docker.list"

echo "==> Docker Engine"

if command -v docker >/dev/null 2>&1; then
    echo "    Already installed: $(docker --version)"
else
    echo "    Adding the Docker package repository"

    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "${KEYRING}"
    sudo chmod a+r "${KEYRING}"

    # shellcheck source=/dev/null
    codename="$(. /etc/os-release && echo "${VERSION_CODENAME}")"

    echo "deb [arch=$(dpkg --print-architecture) signed-by=${KEYRING}] \
https://download.docker.com/linux/ubuntu ${codename} stable" \
        | sudo tee "${LIST}" >/dev/null

    sudo apt-get update
    sudo apt-get install -y --no-install-recommends \
        docker-ce \
        docker-ce-cli \
        containerd.io \
        docker-buildx-plugin \
        docker-compose-plugin

    echo "    Installed $(docker --version)"
fi

echo
echo "==> systemd"

if [[ -f /etc/wsl.conf ]] && grep -q '^\s*systemd\s*=\s*true' /etc/wsl.conf; then
    echo "    Already enabled in /etc/wsl.conf"
else
    if [[ -f /etc/wsl.conf ]] && grep -q '^\[boot\]' /etc/wsl.conf; then
        # A [boot] section exists. Add the setting under it.
        sudo sed -i '/^\[boot\]/a systemd=true' /etc/wsl.conf
    else
        printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf >/dev/null
    fi

    echo "    Enabled in /etc/wsl.conf. A WSL restart is needed."
fi

echo
echo "==> docker group"

if id -nG "${USER}" | grep -qw docker; then
    echo "    ${USER} is already a member."
else
    sudo usermod -aG docker "${USER}"
    echo "    Added ${USER}. A WSL restart is needed."
fi

echo
echo "==> Service"

# This fails if systemd is not running yet. That is expected on the first
# run, because systemd starts only after the WSL restart.
if sudo systemctl enable --now docker >/dev/null 2>&1; then
    echo "    docker service enabled and running"
else
    echo "    Cannot start the service yet. It starts after the WSL restart."
fi

echo
echo "==> Docker setup complete"
echo
echo "    Run this in Windows PowerShell, then open WSL again:"
echo "        wsl --shutdown"
