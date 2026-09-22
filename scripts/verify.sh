#!/usr/bin/env bash
#
# Check the environment. Report every problem, then exit.
#
set -uo pipefail

STAGE="VALIDATION"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

failures=0

check_failed() {
    fail "$1"
    failures=$((failures + 1))
}

stage "Tool versions"

for tool in mise uv git gh node docker; do
    if command -v "${tool}" >/dev/null 2>&1; then
        printf '    %-6s %s\n' "${tool}" "$("${tool}" --version 2>&1 | head -n1)"
    else
        check_failed "${tool} is not on PATH"
    fi
done

stage "Python interpreters"

if command -v uv >/dev/null 2>&1; then
    # Read the installed versions from uv. Do not hardcode a list.
    mapfile -t installed < <(
        uv python list --only-installed \
            | grep -oE '(^|[[:space:]])cpython-3\.[0-9]+\.[0-9]+-' \
            | grep -oE '3\.[0-9]+\.[0-9]+' \
            | sort -u -t. -k2,2n -k3,3n
    )

    if [[ ${#installed[@]} -eq 0 ]]; then
        check_failed "uv has no Python installed"
    else
        for version in "${installed[@]}"; do
            minor="${version%.*}"

            if output="$(uv run --no-project --python "${minor}" \
                             python --version 2>&1)"; then
                printf '    %-6s %s\n' "${minor}" "${output}"
            else
                check_failed "python ${minor} does not run: ${output}"
            fi
        done
    fi
else
    check_failed "uv is not on PATH, so Python cannot be checked"
fi

stage "Shell"

if [[ -r "${HOME}/.oh-my-bash/oh-my-bash.sh" ]]; then
    info "oh-my-bash installed"
else
    check_failed "oh-my-bash is missing"
fi

# mise writes a marked block into ~/.bashrc. Accept either the marker or
# the command itself, so a change in the marker text does not break this.
if grep -qE 'mise:activate|mise activate bash' "${HOME}/.bashrc" 2>/dev/null; then
    info ".bashrc activates mise"
else
    check_failed ".bashrc does not activate mise. New shells find no tools."
fi

if [[ -f "${HOME}/.config/mise/config.toml" ]]; then
    info "global mise config installed"
else
    check_failed "no ~/.config/mise/config.toml. Tools work only in a project."
fi

stage "VS Code"

if [[ -f "${HOME}/.vscode-server/data/Machine/settings.json" ]]; then
    info "machine settings installed"
else
    warn "VS Code machine settings are missing"
fi

stage "Git"

for key in user.name user.email; do
    if value="$(git config --get "${key}")" && [[ -n "${value}" ]]; then
        printf '    %-11s %s\n' "${key}" "${value}"
    else
        check_failed "git ${key} is not set"
    fi
done

# An "includeIf gitdir" rule works only inside a real repository. So make
# an empty one, ask git which email it picks, then remove it.
if [[ -f "${HOME}/.gitconfig-work" && -d "${HOME}/work" ]]; then
    probe="$(mktemp -d "${HOME}/work/.verify-XXXXXX")"
    git -C "${probe}" init --quiet

    work_email="$(git -C "${probe}" config --get user.email 2>/dev/null || true)"
    expected="$(git config --file "${HOME}/.gitconfig-work" --get user.email)"

    rm -rf -- "${probe}"

    if [[ "${work_email}" == "${expected}" ]]; then
        printf '    %-11s %s\n' "in ~/work" "${work_email}"
    else
        check_failed "~/work uses '${work_email}', expected '${expected}'"
    fi
else
    warn "no work identity at ~/.gitconfig-work"
fi

stage "Docker"

if command -v docker >/dev/null 2>&1; then
    if id -nG "${USER}" | grep -qw docker; then
        info "${USER} is in the docker group"
    else
        warn "${USER} is not in the docker group yet. Run: wsl --shutdown"
    fi

    if docker info >/dev/null 2>&1; then
        info "daemon is running"
    else
        warn "the docker daemon does not answer. Run: wsl --shutdown"
    fi
fi

stage "GitHub"

if [[ -f "${HOME}/.ssh/id_ed25519_personal" ]]; then
    info "personal SSH key present"
else
    warn "no personal SSH key"
fi

if gh auth status >/dev/null 2>&1; then
    info "gh is logged in"
else
    warn "gh is not logged in. Run: gh auth login"
fi

if [[ ${failures} -gt 0 ]]; then
    stage "Result"
    info "${failures} check(s) failed"
    exit 1
fi

stage "Result"
info "all checks passed"
