#
# Shared output helpers. Source this file. Do not run it.
#
# Every script prints messages in the same shape:
#
#     ==> STAGE: Title
#         detail
#         WARN: something you should know
#         FAIL: something that is broken
#
# STAGE is one word in capitals. It says which part of the setup you are
# looking at. Each script sets it before it sources this file.
#

STAGE="${STAGE:-SETUP}"

# Two empty lines before each title. This makes the steps easy to find in
# a long log.
stage() { printf '\n\n==> %s: %s\n' "${STAGE}" "$1"; }

info() { printf '    %s\n' "$1"; }
warn() { printf '    WARN: %s\n' "$1"; }
fail() { printf '    FAIL: %s\n' "$1" >&2; }

# mise does not always run hooks and tasks with the tools on PATH. Add the
# two directories that hold them. Without this, a script cannot find uv,
# gh, or mise itself.
for _dir in "${HOME}/.local/bin" "${HOME}/.local/share/mise/shims"; do
    case ":${PATH}:" in
        *":${_dir}:"*) ;;
        *) PATH="${_dir}:${PATH}" ;;
    esac
done

unset _dir
export PATH
