#!/usr/bin/env bash
#
# Set up GitHub access.
#
# Steps:
#   1. Log in to GitHub with the gh command. Git then works at once.
#   2. Make one SSH key for each account. The keys have no passphrase.
#   3. Write a host name for each account in ~/.ssh/config.
#   4. Send each public key to GitHub with gh.
#
# The script never replaces a key that exists. You can run it again.
#
set -euo pipefail

STAGE="GITHUB"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

SSH_DIR="${HOME}/.ssh"
CONFIG="${SSH_DIR}/config"

mkdir -p -- "${SSH_DIR}"
chmod 700 -- "${SSH_DIR}"

interactive() { [[ -t 0 ]]; }

stage "Host key"

# The first connection to github.com normally asks you to accept its host
# key. Fetch the key now, so that later git commands do not stop and wait.
if grep -q '^github.com ' "${SSH_DIR}/known_hosts" 2>/dev/null; then
    info "already known"
elif ssh-keyscan -t rsa,ecdsa,ed25519 github.com \
        >> "${SSH_DIR}/known_hosts" 2>/dev/null; then
    info "added to ${SSH_DIR}/known_hosts"
else
    # ssh-keyscan exits non-zero when the network blocks port 22. Without
    # this guard, set -e would stop the whole bootstrap here.
    warn "could not reach github.com. You will be asked to accept its key."
fi

stage "Browser"

# gh and ori show a login page. WSL has no browser of its own, so they need
# wslview to open the Windows one. wslview comes in the wslu package.
#
# wslu is not in mise.toml on purpose. It sits in the "universe" component,
# and some Ubuntu releases drop it. A missing name there stops the whole
# bootstrap. Here it is only a convenience, so a failure is a warning.
if command -v wslview >/dev/null 2>&1; then
    info "wslview is installed. A login page can open by itself."
elif ! apt-cache show wslu >/dev/null 2>&1; then
    warn "this Ubuntu has no wslu package."
    warn "you will copy each login link into Windows by hand."
elif sudo env DEBIAN_FRONTEND=noninteractive apt-get install -y wslu; then
    info "installed wslu. A login page can now open by itself."
else
    warn "wslu did not install."
    warn "you will copy each login link into Windows by hand."
fi

stage "Login"

# The admin:public_key scope lets gh send the SSH keys made below.
if ! command -v gh >/dev/null 2>&1; then
    info "gh is not installed. Skipping the login."
elif gh auth status >/dev/null 2>&1; then
    info "already logged in"
elif ! interactive; then
    info "no terminal. Skipping the login."
    info "run this later: gh auth login --scopes admin:public_key"
else
    gh auth login --git-protocol ssh --scopes admin:public_key \
        || info "login failed or cancelled. You can run it again later."
fi

upload_key() {
    local label="$1"
    local key="$2"
    local title
    title="$(hostname)-${label}"

    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        if gh ssh-key list 2>/dev/null \
                | grep -qF "$(awk '{print $2}' "${key}.pub")"; then
            info "public key is already on GitHub"
            return
        fi

        if gh ssh-key add "${key}.pub" --title "${title}" 2>/dev/null; then
            info "sent the public key to GitHub as '${title}'"
            return
        fi

        warn "upload failed. The token may miss the admin:public_key scope."
        warn "fix it with: gh auth refresh -s admin:public_key"
    fi

    info "add this public key at https://github.com/settings/keys :"
    echo
    cat -- "${key}.pub"
    echo
}

setup_account() {
    local label="$1"
    local alias_name="github-${label}"
    local key="${SSH_DIR}/id_ed25519_${label}"

    stage "Account: ${label}"

    if [[ -f "${key}" ]]; then
        info "key ${key} exists. Keeping it."
    else
        # -N "" means no passphrase, so the setup does not stop here.
        ssh-keygen -t ed25519 -N "" -C "${label}@$(hostname)" -f "${key}" \
            >/dev/null
        info "made ${key}"
    fi

    if [[ -f "${CONFIG}" ]] && grep -q "^Host ${alias_name}$" -- "${CONFIG}"; then
        info "host ${alias_name} is already in ${CONFIG}"
    else
        # The host name picks the right key for the right account:
        #   git clone git@github-personal:USER/REPO.git
        cat >> "${CONFIG}" <<EOF

Host ${alias_name}
    HostName github.com
    User git
    IdentityFile ${key}
    IdentitiesOnly yes
EOF
        chmod 600 -- "${CONFIG}"
        info "added host ${alias_name} to ${CONFIG}"
    fi

    upload_key "${label}" "${key}"
}

setup_account "personal"

if interactive; then
    stage "Work account"
    read -r -p "    Set up a work account too? [Y/n] " answer
else
    answer="n"
fi

if [[ ! "${answer}" =~ ^[Nn]([Oo])?$ ]]; then
    info "log in to the work account. gh can hold several accounts."
    info "change account later with: gh auth switch"
    echo

    if command -v gh >/dev/null 2>&1; then
        gh auth login --git-protocol ssh --scopes admin:public_key || true
    fi

    setup_account "work"
fi

stage "Next step"

info "test the connection with: ssh -T git@github-personal"
