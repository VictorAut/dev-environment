#!/usr/bin/env bash
#
# Set up GitHub access.
#
# Steps:
#   1. Log in to GitHub with the gh command. This makes git work at once.
#   2. Create one SSH key for each account. The keys have no passphrase.
#   3. Write a host alias for each account in ~/.ssh/config.
#   4. Upload each public key to GitHub with gh.
#
# The script never replaces an existing key. You can run it again safely.
#
set -euo pipefail

SSH_DIR="${HOME}/.ssh"
CONFIG="${SSH_DIR}/config"

mkdir -p -- "${SSH_DIR}"
chmod 700 -- "${SSH_DIR}"

interactive() { [[ -t 0 ]]; }

# ---------------------------------------------------------------------------
# GitHub host key
#
# The first connection to github.com normally asks you to accept its host key.
# Fetch the key now, so that later git commands do not stop and wait.
# ---------------------------------------------------------------------------

echo "==> GitHub host key"

if grep -q '^github.com ' "${SSH_DIR}/known_hosts" 2>/dev/null; then
    echo "    Already known."
else
    ssh-keyscan -t rsa,ecdsa,ed25519 github.com >> "${SSH_DIR}/known_hosts" 2>/dev/null
    echo "    Added to ${SSH_DIR}/known_hosts"
fi

# ---------------------------------------------------------------------------
# gh login
#
# The admin:public_key scope lets gh upload the SSH keys created below.
# ---------------------------------------------------------------------------

echo
echo "==> GitHub login"

if ! command -v gh >/dev/null 2>&1; then
    echo "    gh is not installed. Skipping login."
elif gh auth status >/dev/null 2>&1; then
    echo "    Already logged in."
elif ! interactive; then
    echo "    No terminal available. Skipping login."
    echo "    Run this later: gh auth login --scopes admin:public_key"
else
    gh auth login --git-protocol ssh --scopes admin:public_key || {
        echo "    Login failed or cancelled. You can run it again later."
    }
fi

# ---------------------------------------------------------------------------
# One key and one host alias per account
# ---------------------------------------------------------------------------

setup_account() {
    local label="$1"
    local alias_name="github-${label}"
    local key="${SSH_DIR}/id_ed25519_${label}"

    echo
    echo "==> Account: ${label}"

    if [[ -f "${key}" ]]; then
        echo "    Key ${key} already exists. Keeping it."
    else
        # -N "" means no passphrase, so the bootstrap does not stop here.
        ssh-keygen -t ed25519 -N "" -C "${label}@$(hostname)" -f "${key}" \
            >/dev/null
        echo "    Created ${key}"
    fi

    if [[ -f "${CONFIG}" ]] && grep -q "^Host ${alias_name}$" -- "${CONFIG}"; then
        echo "    Host ${alias_name} already in ${CONFIG}"
    else
        # The alias picks the right key for the right account. Clone with:
        #   git clone git@${alias_name}:USER/REPO.git
        cat >> "${CONFIG}" <<EOF

Host ${alias_name}
    HostName github.com
    User git
    IdentityFile ${key}
    IdentitiesOnly yes
EOF
        chmod 600 -- "${CONFIG}"
        echo "    Added host ${alias_name} to ${CONFIG}"
    fi

    upload_key "${label}" "${key}"
}

upload_key() {
    local label="$1"
    local key="$2"
    local title
    title="$(hostname)-${label}"

    if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
        if gh ssh-key list 2>/dev/null | grep -qF "$(awk '{print $2}' "${key}.pub")"; then
            echo "    Public key already on GitHub."
            return
        fi

        if gh ssh-key add "${key}.pub" --title "${title}" 2>/dev/null; then
            echo "    Uploaded public key to GitHub as '${title}'."
            return
        fi

        echo "    Upload failed. The token may lack the admin:public_key scope."
        echo "    Fix it with: gh auth refresh -s admin:public_key"
    fi

    echo "    Add this public key at https://github.com/settings/keys :"
    echo
    cat -- "${key}.pub"
    echo
}

setup_account "personal"

echo
if interactive; then
    read -r -p "==> Set up a work account too? [y/N] " answer
else
    answer="n"
fi

if [[ "${answer}" =~ ^[Yy]$ ]]; then
    echo
    echo "    Log in to the work account. gh can hold several accounts."
    echo "    Switch between them later with: gh auth switch"
    echo

    if command -v gh >/dev/null 2>&1; then
        gh auth login --git-protocol ssh --scopes admin:public_key || true
    fi

    setup_account "work"
fi

echo
echo "==> Test the connection with:"
echo "        ssh -T git@github-personal"
echo
echo "==> SSH setup complete"
