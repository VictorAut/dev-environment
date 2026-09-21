#!/usr/bin/env bash
#
# Check the development environment. Report every problem, then exit.
#
set -uo pipefail

failures=0

fail() {
    printf '    FAIL: %s\n' "$1"
    failures=$((failures + 1))
}

warn() {
    printf '    WARN: %s\n' "$1"
}

echo "==> Tool versions"

for tool in mise uv git gh node; do
    if command -v "${tool}" >/dev/null 2>&1; then
        printf '    %-6s %s\n' "${tool}" "$("${tool}" --version 2>&1 | head -n1)"
    else
        fail "${tool} is not on PATH"
    fi
done

echo
echo "==> Python interpreters"

if command -v uv >/dev/null 2>&1; then
    # Read the installed versions from uv. Do not hardcode a version list.
    mapfile -t installed < <(
        uv python list --only-installed \
            | grep -oE '(^|[[:space:]])cpython-3\.[0-9]+\.[0-9]+-' \
            | grep -oE '3\.[0-9]+\.[0-9]+' \
            | sort -u -t. -k2,2n -k3,3n
    )

    if [[ ${#installed[@]} -eq 0 ]]; then
        fail "uv has no Python installed"
    else
        for version in "${installed[@]}"; do
            minor="${version%.*}"

            if output="$(uv run --no-project --python "${minor}" \
                             python --version 2>&1)"; then
                printf '    %-6s %s\n' "${minor}" "${output}"
            else
                fail "python ${minor} does not run: ${output}"
            fi
        done
    fi
else
    fail "uv is not on PATH, so Python cannot be checked"
fi

echo
echo "==> Shell"

if [[ -r "${HOME}/.oh-my-bash/oh-my-bash.sh" ]]; then
    echo "    oh-my-bash installed"
else
    fail "oh-my-bash is missing"
fi

# mise writes a marked block into ~/.bashrc. Check for the block, not for
# a line, so a renamed command still passes.
if grep -q 'mise:activate' "${HOME}/.bashrc" 2>/dev/null; then
    echo "    .bashrc activates mise"
else
    fail ".bashrc does not activate mise. New shells will not find the tools."
fi

if [[ -f "${HOME}/.config/mise/config.toml" ]]; then
    echo "    Global mise config installed"
else
    fail "no ~/.config/mise/config.toml. Tools will not work outside a project."
fi

echo
echo "==> VS Code"

if [[ -f "${HOME}/.vscode-server/data/Machine/settings.json" ]]; then
    echo "    Machine settings installed"
else
    warn "VS Code machine settings are missing"
fi

echo
echo "==> Git"

for key in user.name user.email; do
    if value="$(git config --get "${key}")" && [[ -n "${value}" ]]; then
        printf '    %-11s %s\n' "${key}" "${value}"
    else
        fail "git ${key} is not set"
    fi
done

# Check that a repository under ~/work uses the work identity.
#
# An "includeIf gitdir" rule applies only inside a real repository. So the
# check creates an empty one, asks git which email it would use, and then
# removes it. This tests the same rule that a commit would use.
if [[ -f "${HOME}/.gitconfig-work" && -d "${HOME}/work" ]]; then
    probe="$(mktemp -d "${HOME}/work/.verify-XXXXXX")"
    git -C "${probe}" init --quiet

    work_email="$(git -C "${probe}" config --get user.email 2>/dev/null || true)"
    expected="$(git config --file "${HOME}/.gitconfig-work" --get user.email)"

    rm -rf -- "${probe}"

    if [[ "${work_email}" == "${expected}" ]]; then
        printf '    %-11s %s\n' "in ~/work" "${work_email}"
    else
        fail "repositories in ~/work use '${work_email}', expected '${expected}'"
    fi
else
    warn "no work identity at ~/.gitconfig-work"
fi

echo
echo "==> Docker"

if command -v docker >/dev/null 2>&1; then
    echo "    Installed: $(docker --version)"

    if id -nG "${USER}" | grep -qw docker; then
        echo "    ${USER} is in the docker group"
    else
        warn "${USER} is not in the docker group yet. Run: wsl --shutdown"
    fi

    if docker info >/dev/null 2>&1; then
        echo "    Daemon is running"
    else
        warn "the docker daemon is not reachable. Run: wsl --shutdown"
    fi
else
    fail "docker is not installed"
fi

echo
echo "==> SSH"

if [[ -f "${HOME}/.ssh/id_ed25519_personal" ]]; then
    echo "    Personal key present"
else
    warn "no personal SSH key"
fi

if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    echo "    gh is logged in"
else
    warn "gh is not logged in. Run: gh auth login"
fi

echo

if [[ ${failures} -gt 0 ]]; then
    echo "==> ${failures} check(s) failed"
    exit 1
fi

echo "==> All checks passed"
