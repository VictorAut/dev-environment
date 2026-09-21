#!/usr/bin/env bash
#
# Set the git identity.
#
# Git chooses the identity from the directory of the repository:
#
#   ~/personal/...  uses the personal name and email
#   ~/work/...      uses the work name and email
#
# This happens through "includeIf" rules in ~/.gitconfig. Git reads the path
# of the repository and loads the matching file. You do not need to set
# anything for each repository.
#
set -euo pipefail

PERSONAL_FILE="${HOME}/.gitconfig-personal"
WORK_FILE="${HOME}/.gitconfig-work"

interactive() { [[ -t 0 ]]; }

write_identity() {
    local file="$1"
    local name="$2"
    local email="$3"

    cat > "${file}" <<EOF
[user]
    name = ${name}
    email = ${email}
EOF
}

ask_identity() {
    local label="$1"
    local file="$2"
    local name
    local email

    if [[ -f "${file}" ]]; then
        echo "    ${label}: already set in ${file}"
        return 0
    fi

    if ! interactive; then
        echo "    ${label}: no terminal available. Create ${file} later."
        return 0
    fi

    read -r -p "    ${label} name:  " name
    read -r -p "    ${label} email: " email

    if [[ -z "${name}" || -z "${email}" ]]; then
        echo "    ${label}: skipped."
        return 0
    fi

    write_identity "${file}" "${name}" "${email}"
    echo "    ${label}: written to ${file}"
}

echo "==> Git identities"

ask_identity "Personal" "${PERSONAL_FILE}"
ask_identity "Work" "${WORK_FILE}"

echo
echo "==> Directory rules"

# The personal identity is also the default, for repositories that are
# outside both directories.
if [[ -f "${PERSONAL_FILE}" ]]; then
    git config --global include.path "${PERSONAL_FILE}"
    echo "    Default identity: personal"
fi

# The path must end with a slash. Git then matches every repository below it.
if [[ -f "${PERSONAL_FILE}" ]]; then
    git config --global "includeIf.gitdir:~/personal/.path" "${PERSONAL_FILE}"
    echo "    ~/personal/ -> personal identity"
fi

if [[ -f "${WORK_FILE}" ]]; then
    git config --global "includeIf.gitdir:~/work/.path" "${WORK_FILE}"
    echo "    ~/work/     -> work identity"
fi

echo
echo "==> Git defaults"

# These remove the warnings that git prints on a new machine.
git config --global init.defaultBranch main
git config --global pull.rebase true

echo "    init.defaultBranch  main"
echo "    pull.rebase         true"

echo
echo "==> Git setup complete"
