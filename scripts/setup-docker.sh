#!/usr/bin/env bash
#
# Finish the Docker setup.
#
# mise installs the packages and writes /etc/wsl.conf. Two things are
# left. Both need a full WSL restart before they work:
#
#   1. Your user must join the "docker" group. If not, every command needs
#      sudo.
#   2. systemd must run, so that the docker service starts.
#
# Restart from Windows PowerShell:
#
#      wsl --shutdown
#
# Note: a member of the "docker" group can start a container as root. On
# this machine that is the same as root access.
#
set -euo pipefail

STAGE="DOCKER"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

stage "User group"

if id -nG "${USER}" | grep -qw docker; then
    info "${USER} is already a member"
else
    sudo usermod -aG docker "${USER}"
    info "added ${USER}. A WSL restart is needed."
fi

stage "Service"

# This fails while systemd is not running. That is normal on the first
# run, because systemd starts only after the WSL restart.
if sudo systemctl enable --now docker >/dev/null 2>&1; then
    info "enabled and running"
else
    info "cannot start it yet. It starts after the WSL restart."
fi
