#!/usr/bin/env bash
#
# Set the git identity.
#
# Git picks the identity from the location of the repository:
#
#   ~/personal/...  uses the personal name and email
#   ~/work/...      uses the work name and email
#
# This works through "includeIf" rules in ~/.gitconfig. Git reads the path
# of the repository and loads the file that matches. You never set an
# identity for a single repository.
#
set -euo pipefail

STAGE="GIT"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

PERSONAL_FILE="${HOME}/.gitconfig-personal"
WORK_FILE="${HOME}/.gitconfig-work"

interactive() { [[ -t 0 ]]; }

ask_identity() {
    local label="$1"
    local file="$2"
    local name
    local email

    if [[ -f "${file}" ]]; then
        info "${label}: already set in ${file}"
        return 0
    fi

    if ! interactive; then
        info "${label}: no terminal. Make ${file} later."
        return 0
    fi

    read -r -p "    ${label} name:  " name
    read -r -p "    ${label} email: " email

    if [[ -z "${name}" || -z "${email}" ]]; then
        info "${label}: skipped"
        return 0
    fi

    cat > "${file}" <<EOF
[user]
    name = ${name}
    email = ${email}
EOF

    info "${label}: written to ${file}"
}

# The rules below point at these directories.
mkdir -p -- "${HOME}/personal" "${HOME}/work"

stage "Identities"

ask_identity "Personal" "${PERSONAL_FILE}"
ask_identity "Work" "${WORK_FILE}"

stage "Directory rules"

# The personal identity is also the default. It covers repositories that
# are in neither directory.
if [[ -f "${PERSONAL_FILE}" ]]; then
    git config --global include.path "${PERSONAL_FILE}"
    git config --global "includeIf.gitdir:~/personal/.path" "${PERSONAL_FILE}"

    info "default     personal"
    info "~/personal  personal"
fi

# The path must end with a slash. Git then matches every repository below
# that directory.
if [[ -f "${WORK_FILE}" ]]; then
    git config --global "includeIf.gitdir:~/work/.path" "${WORK_FILE}"
    info "~/work      work"
fi

stage "Global ignore"

# .dev/ holds the notes for one change: the specification, review output.
# It sits next to the code, because that is where an agent reads. It must
# not appear in any project's .gitignore, because it is yours, not the
# project's. A global ignore file keeps it out of every repository.
IGNORE_FILE="${HOME}/.config/git/ignore"

mkdir -p -- "$(dirname -- "${IGNORE_FILE}")"
touch -- "${IGNORE_FILE}"

git config --global core.excludesFile "${IGNORE_FILE}"

# .dev/ holds your notes. .memsearch/ holds the memory index. Neither
# belongs to the project.
for pattern in '.dev/' '.memsearch/'; do
    if grep -qxF "${pattern}" -- "${IGNORE_FILE}"; then
        info "${pattern} is already ignored everywhere"
    else
        printf '%s\n' "${pattern}" >> "${IGNORE_FILE}"
        info "added ${pattern} to ${IGNORE_FILE}"
    fi
done

stage "Defaults"

# These remove the messages that git prints on a new machine.
git config --global init.defaultBranch main
git config --global pull.rebase true

info "init.defaultBranch  main"
info "pull.rebase         true"
