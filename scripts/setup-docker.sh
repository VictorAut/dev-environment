#!/usr/bin/env bash
#
# Finish the Docker setup.
#
# mise installs the packages and writes /etc/wsl.conf. Two things are left,
# and both need a full WSL restart before they work:
#
#   1. Your user must join the "docker" group. Without it, every command
#      needs sudo.
#   2. systemd must be running, so that the docker service starts.
#
# Restart from Windows PowerShell:
#
#      wsl --shutdown
#
# Note: a member of the "docker" group can start a container as root. On
# this machine that is the same as having root access.
#
set -euo pipefail

echo "==> docker group"

if id -nG "${USER}" | grep -qw docker; then
    echo "    ${USER} is already a member."
else
    sudo usermod -aG docker "${USER}"
    echo "    Added ${USER}. A WSL restart is needed."
fi

echo
echo "==> docker service"

# This fails while systemd is not running. That is expected on the first
# run, because systemd starts only after the WSL restart.
if sudo systemctl enable --now docker >/dev/null 2>&1; then
    echo "    Enabled and running."
else
    echo "    Cannot start it yet. It starts after the WSL restart."
fi
