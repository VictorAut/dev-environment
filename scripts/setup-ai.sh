#!/usr/bin/env bash
#
# Point both AI agents at one instruction file, and log in to OpenRouter.
#
# mise installs claude-code, codex and ori, and copies the instructions to
# ~/.config/agents/AGENTS.md. This script links both agents to that file, so
# you edit it once and both see the change.
#
# You can run it again. Each step checks its own result first.
#
set -euo pipefail

STAGE="AI"
# shellcheck source=lib.sh
source "$(dirname -- "${BASH_SOURCE[0]}")/lib.sh"

SHARED="${HOME}/.config/agents/AGENTS.md"

interactive() { [[ -t 0 ]]; }

mkdir -p -- "${HOME}/.claude" "${HOME}/.codex" "${HOME}/.config/agents"

link_instructions() {
    local target="$1"
    local label="$2"

    if [[ -L "${target}" && "$(readlink -f "${target}")" == "${SHARED}" ]]; then
        info "${label}: already linked"
        return 0
    fi

    # Keep anything already there. It may be hand-written.
    if [[ -e "${target}" || -L "${target}" ]]; then
        local backup="${target}.backup.$(date +%Y%m%d%H%M%S)"
        mv -- "${target}" "${backup}"
        info "${label}: old file moved to ${backup}"
    fi

    ln -s -- "${SHARED}" "${target}"
    info "${label}: linked to ${SHARED}"
}

stage "Shared instructions"

if [[ ! -f "${SHARED}" ]]; then
    fail "${SHARED} is missing. mise should have copied it from ai/AGENTS.md."
    exit 1
fi

link_instructions "${HOME}/.claude/CLAUDE.md" "Claude Code"
link_instructions "${HOME}/.codex/AGENTS.md" "Codex"

stage "Memory"

# memsearch indexes your past sessions and reminds Claude Code of them.
# It embeds text on this machine with ONNX, so it needs no API key and
# costs nothing to run. The search does not use the model, so it works the
# same whichever model you are on.
if ! command -v claude >/dev/null 2>&1; then
    warn "claude is not on PATH. Skipping the memory plugin."
elif claude plugin list 2>/dev/null | grep -q 'memsearch'; then
    info "memsearch is already installed"
else
    claude plugin marketplace add zilliztech/memsearch \
        && claude plugin install memsearch@memsearch-plugins \
        && info "installed memsearch" \
        || warn "could not install memsearch. Claude Code works without it."
fi

stage "OpenRouter"

if ! command -v ori >/dev/null 2>&1; then
    warn "ori is not on PATH. Install it with:"
    warn "    curl -fsSL https://openrouter.ai/labs/ori/install.sh | bash"
elif ! interactive; then
    info "no terminal. Log in later with: ori login"
else
    info "ori opens a browser to log in to OpenRouter."
    info "skip this if you are already logged in."
    read -r -p "    Log in now? [y/N] " answer

    if [[ "${answer}" =~ ^[Yy]([Ee][Ss])?$ ]]; then
        ori login || warn "login failed or cancelled. Run 'ori login' later."
    else
        info "skipped. Run 'ori login' when you are ready."
    fi
fi

stage "How to use it"

info "in ~/personal: claude   runs \${AI_PERSONAL_MODEL} on OpenRouter"
info "anywhere else: claude   runs an Anthropic model"
info "force Anthropic:        command claude"
info "Codex on OpenRouter:    ori codex --model \"\${AI_PERSONAL_MODEL}\""
info ""
info "How to work with the agents: ~/.config/agents/HOWTO.md"
