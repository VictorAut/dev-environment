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

for tool in mise uv git gh claude codex ori; do
    if ! command -v "${tool}" >/dev/null 2>&1; then
        check_failed "${tool} is not on PATH"
        continue
    fi

    # ori prints JSON when it is not writing to a terminal, so cut the
    # output short rather than showing a stray brace.
    version="$("${tool}" --version 2>&1 | head -n1 | cut -c1-40)"

    printf '    %-6s %s\n' "${tool}" "${version}"
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
        # A warning, not a failure. verify.sh is the final hook, so a
        # failure here marks the whole bootstrap as failed.
        warn "git ${key} is not set. Run: git config --global ${key} '...'"
    fi
done

# An "includeIf gitdir" rule works only inside a real repository. So make
# an empty one, ask git which email it picks, then remove it.
if [[ -f "${HOME}/.gitconfig-work" && -d "${HOME}/work" ]]; then
    if probe="$(mktemp -d "${HOME}/work/.verify-XXXXXX")"; then
    git -C "${probe}" init --quiet

    work_email="$(git -C "${probe}" config --get user.email 2>/dev/null || true)"
    expected="$(git config --file "${HOME}/.gitconfig-work" --get user.email)"

    rm -rf -- "${probe}"

    if [[ "${work_email}" == "${expected}" ]]; then
        printf '    %-11s %s\n' "in ~/work" "${work_email}"
    else
        check_failed "~/work uses '${work_email}', expected '${expected}'"
    fi
    fi
else
    warn "no work identity at ~/.gitconfig-work"
fi

stage "AI agents"

shared="${HOME}/.config/agents/AGENTS.md"

if [[ -f "${shared}" ]]; then
    info "shared instructions at ${shared}"
else
    check_failed "no ${shared}"
fi

# Both agents must read the same file, or they behave differently.
for pair in "Claude Code:${HOME}/.claude/CLAUDE.md" "Codex:${HOME}/.codex/AGENTS.md"; do
    label="${pair%%:*}"
    path="${pair#*:}"

    if [[ "$(readlink -f "${path}" 2>/dev/null)" == "${shared}" ]]; then
        printf '    %-12s reads the shared file\n' "${label}"
    else
        check_failed "${label} does not read ${shared} (${path})"
    fi
done

for agent in investigator reviewer; do
    if [[ -f "${HOME}/.claude/agents/${agent}.md" ]]; then
        printf '    %-12s subagent installed\n' "${agent}"
    else
        check_failed "no ~/.claude/agents/${agent}.md"
    fi
done

if [[ -f "${HOME}/.config/agents/spec-template.md" ]]; then
    info "spec template installed"
else
    check_failed "no ~/.config/agents/spec-template.md"
fi

if command -v claude >/dev/null 2>&1 \
        && claude plugin list 2>/dev/null | grep -q 'memsearch'; then
    info "memsearch memory installed"
else
    warn "memsearch is not installed. Run: claude plugin install memsearch@memsearch-plugins"
fi

if command -v ori >/dev/null 2>&1; then
    if ori auth >/dev/null 2>&1; then
        info "ori is logged in to OpenRouter"
    else
        warn "ori is not logged in. Run: ori login"
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
