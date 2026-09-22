# dev-environment

A one-shot bootstrap for a fresh Ubuntu WSL environment.

The machine setup is declared in [mise.toml](mise.toml). `mise bootstrap`
reads that file and applies it: system packages, repositories, dotfiles,
shell activation and tools. A few steps need a terminal, so they stay as
scripts in [scripts/](scripts/).

Nothing is left behind. You can delete this repository afterwards.

## Install

Set up the font first (see the next section), then run two commands:

```bash
curl -fsSL https://mise.run | sh
~/.local/bin/mise bootstrap \
    --from https://github.com/VictorAut/dev-environment.git \
    --yes \
    --force-dotfiles
```

Each flag does one thing:

| Flag | What it does |
|---|---|
| `--from` | clones the repository into mise's own data directory, so nothing lands in your home directory |
| `--yes` | answers every question with yes, so the setup runs without stopping |
| `--force-dotfiles` | lets mise replace the `~/.bashrc` that Ubuntu ships. Without it, mise stops rather than change a file it does not own |

To see what would happen, and change nothing, add `--dry-run`.

This needs **mise 2026.9.12 or newer**, which is when `[bootstrap]` and
`[dotfiles]` arrived. The `curl` line above installs the newest version, so
a new machine is always fine. On an older machine, run `mise self-update`.
`mise.toml` sets `min_version`, so an old mise stops with a clear message
instead of quietly doing nothing.

If you have already cloned the repository, run `./bootstrap.sh` instead. It
does the same thing.

The bootstrap asks you for your personal and work git identities, your
GitHub login in a browser, and whether you also want a work account.
Everything else runs without input.

When it finishes:

1. Open a new shell.
2. Run `wsl --shutdown` in Windows PowerShell, then open WSL again. Docker
   needs this.

## Windows Terminal

Do this before the bootstrap, or the prompt will look broken.

The `powerbash10k` prompt from oh-my-bash draws arrows, a git branch mark
and a Python mark. These are not normal letters. They are icons stored in
the unused part of a font. The terminal on **Windows** chooses the font, so
nothing inside WSL can fix a missing icon. A normal font shows an empty box
or a question mark instead.

You need a **Nerd Font**. A Nerd Font is a normal font with about 9,000
extra icons added to it.

### 1. Install the font on Windows

1. Download a font from [nerdfonts.com](https://www.nerdfonts.com/font-downloads).
   `CaskaydiaCove Nerd Font` is a good default. It is Microsoft's Cascadia
   Code with the icons added.
2. Unzip the file.
3. Select all the `.ttf` files, right click, and choose **Install for all
   users**. Plain **Install** also works, but only for your account.

Do not use the files that end in `Windows Compatible`. Older names, newer
files: both work, but mixing them makes the font name confusing.

### 2. Point Windows Terminal at the font

The simple way:

1. Open Windows Terminal.
2. Press `Ctrl` + `,` to open **Settings**.
3. In the left list, choose your **Ubuntu** profile.
4. Open **Appearance**.
5. Set **Font face** to `CaskaydiaCove Nerd Font`.
6. Click **Save**.

The exact name matters. Use the name as it appears in the dropdown list.
Some downloads install as `CaskaydiaCove NF` instead.

### 3. Or edit the JSON directly

This is faster, and it applies the font to every profile at once.

Press `Ctrl` + `Shift` + `,` in Windows Terminal to open `settings.json`.
The file is at:

```
%LOCALAPPDATA%\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json
```

Add a `defaults` block inside `profiles`. Everything in `defaults` applies
to all profiles, so you do not repeat it for each one:

```json
{
    "profiles": {
        "defaults": {
            "font": {
                "face": "CaskaydiaCove Nerd Font",
                "size": 11
            },
            "colorScheme": "One Half Dark",
            "padding": "8",
            "useAcrylic": false
        },
        "list": [
        ]
    }
}
```

Keep the `list` section as it already is. Only add the `defaults` block
next to it.

To make Ubuntu open by default, and start in your home directory, find the
Ubuntu entry inside `list` and add:

```json
{
    "name": "Ubuntu",
    "startingDirectory": "//wsl$/Ubuntu/home/YOUR_USERNAME"
}
```

Then set the top-level `defaultProfile` to the `guid` of that Ubuntu entry.

### 4. Check that it worked

Open a new WSL shell and run:

```bash
echo -e "     "
```

You should see an arrow, a reversed arrow, the GitHub mark, the Python
mark, a database and a folder. Empty boxes mean the font is not applied.
The usual causes are a wrong font name, or installing only the `Mono` or
`Propo` variant.

### 5. The VS Code terminal

VS Code has its own font setting and does not read the Windows Terminal
one. In VS Code on Windows, open Settings and set:

```json
"terminal.integrated.fontFamily": "CaskaydiaCove Nerd Font"
```

## What it installs

| Item | Declared in | Notes |
|---|---|---|
| System packages | `[bootstrap.packages]` | base tools, compilers, build libraries |
| Docker Engine | `[bootstrap.packages]` | Docker Desktop is not needed |
| oh-my-bash | `[bootstrap.repos]` | theme `powerbash10k` |
| `~/.bashrc` | `[dotfiles]` | copied from `shell/bashrc` |
| Global mise config | `[dotfiles]` | copied from `mise/global-config.toml` |
| VS Code settings | `[dotfiles]` | copied from `vscode/settings.json` |
| `/etc/wsl.conf` | `[bootstrap.files]` | turns on systemd |
| mise activation | `shell/bashrc` | the last line of the copied `~/.bashrc` |
| `uv`, `gh`, `node` | `[tools]` | |
| Python 3.10 to latest | `scripts/install-pythons.sh` | the version list is found at run time |
| Git identities | `scripts/setup-git.sh` | different email in `~/personal` and `~/work` |
| SSH keys | `scripts/setup-ssh.sh` | one per GitHub account, no passphrase |
| VS Code extensions | `scripts/install-vscode.sh` | from `vscode/extensions.txt` |

## Why some steps are scripts

`mise bootstrap` is declarative. These steps are not, so they run from
`[tasks.bootstrap]` after the tools are installed:

- **Python** — the list of versions is worked out while it runs, so a new
  Python release needs no change here.
- **Git identities and SSH keys** — these ask you questions.
- **VS Code extensions** — these need the `code` command, which may not
  exist yet.
- **Docker group and service** — these need your user name and a running
  systemd.

# Usage

## Which tool does what

There is one rule. Follow it and the two tools never fight:

| You need | Use | Where it is recorded |
|---|---|---|
| A Python interpreter | uv | `.python-version`, `pyproject.toml` |
| Python libraries | uv | `pyproject.toml`, `uv.lock` |
| Any other tool: node, terraform, jq | mise | `mise.toml` in the project |
| A command you want everywhere | mise, global | `~/.config/mise/config.toml` |
| A Python command you want everywhere | `uv tool` | its own isolated environment |

Never install a project's tools globally. A global version is a version
your colleagues and your CI do not have.

## Start a new Python project

```bash
mkdir -p ~/personal/my-project
cd ~/personal/my-project

uv init --python 3.13
```

`uv init` writes three things:

| File | What it holds |
|---|---|
| `pyproject.toml` | the project name, the Python version, the dependencies |
| `.python-version` | the exact interpreter for this directory |
| `main.py` | a starting file |

Then add what you need:

```bash
uv add requests polars          # libraries the project needs to run
uv add --dev pytest ruff        # libraries only you need, for development
uv remove polars                # take one out again
```

Each command updates `pyproject.toml`, solves the versions, writes
`uv.lock`, and installs into `.venv` in the project. You do not create the
virtual environment and you do not activate it.

Run things inside the project:

```bash
uv run main.py
uv run pytest
uv run ruff check .
```

`uv run` always uses the project environment. That is why you never need
`source .venv/bin/activate`.

Commit `pyproject.toml` and `uv.lock`. Do not commit `.venv`.

## Work on a project someone else made

```bash
git clone git@github-personal:VictorAut/some-repo.git
cd some-repo

mise install     # only if the project has a mise.toml
uv sync          # only if the project has a pyproject.toml
```

`uv sync` builds the exact environment written in `uv.lock`, down to the
patch version. Everyone on the project gets the same one.

## Pin the non-Python tools of a project

```bash
cd ~/work/some-repo

mise use node@22          # writes mise.toml and installs node 22
mise use terraform@1.13
mise use --pin            # replace "latest" with the exact version
```

`mise use` creates or updates `mise.toml` in the current directory. Commit
that file. When anyone enters the directory, mise switches to those
versions automatically, and switches back on the way out.

```bash
mise ls                   # which versions are active here, and why
mise install              # install everything mise.toml asks for
mise outdated             # what has a newer version
mise upgrade              # move to it
```

A project version always beats the global one.

## Commands you want everywhere

```bash
mise use --global ripgrep@latest    # any tool, added to ~/.config/mise/config.toml
uv tool install ruff                # a Python command, in its own environment
uv tool list
uvx ruff check .                    # run a Python command once, install nothing
mise exec node@20 -- node --version # run one command with a different version
```

`uv tool` replaces `pipx`. Never use `pip install --user`: it mixes project
libraries into your home directory, and nothing records what you did.

## Python versions

```bash
uv python list                      # installed, and available to download
uv python install 3.14              # add one
uv run --python 3.12 script.py      # run one file with a chosen version
uv venv --python 3.13               # a virtual environment outside a project
```

`scripts/install-pythons.sh` installs every stable release from 3.10
upwards. Run it again after a new Python comes out.

## Project tasks

Put repeated commands in the project's `mise.toml`, so they are the same
for everyone:

```toml
[tasks.test]
description = "Run the tests"
run = "uv run pytest"

[tasks.lint]
description = "Check the code"
run = ["uv run ruff check .", "uv run ruff format --check ."]
```

```bash
mise run test
mise tasks          # list what this project defines
```

# Reference

## VS Code

VS Code runs on Windows and connects to WSL. Set it up once:

1. On Windows, install VS Code and its **WSL** extension
   (`ms-vscode-remote.remote-wsl`).
2. From a WSL shell, run `code .` in any directory. VS Code opens connected
   to WSL. You can also press `Ctrl+Shift+P` in VS Code and choose
   **WSL: Connect to WSL**.

mise copies your settings to `~/.vscode-server/data/Machine/settings.json`.
The extensions need the `code` command, which comes from the Windows side
and does not exist on a brand new machine. So on the first bootstrap they
are skipped. Connect once as above, then run `scripts/install-vscode.sh`.

## Git identities

Git chooses your name and email from the location of the repository:

| Location | Identity |
|---|---|
| `~/personal/...` | personal |
| `~/work/...` | work |
| anywhere else | personal |

The bootstrap asks for both and writes `~/.gitconfig-personal` and
`~/.gitconfig-work`. `~/.gitconfig` then points at them with `includeIf`
rules. You never set an identity per repository.

Check which one a repository uses:

```bash
git config user.email
```

## Cloning your own repositories

You have two GitHub accounts, so each one gets its own key and its own host
name. Replace `github.com` in any URL you copy from the website:

```bash
git clone git@github-personal:VictorAut/some-repo.git
git clone git@github-work:some-org/some-repo.git
```

A plain `github.com` URL may use the wrong key, and GitHub will then treat
you as the wrong user.

## Docker

Docker Engine runs inside WSL. Two settings need a full WSL restart before
they work: systemd, which starts the docker service, and your membership of
the `docker` group, which lets you run docker without `sudo`.

```powershell
wsl --shutdown
```

Open WSL again, then check it:

```bash
docker run --rm hello-world
```

Note: a member of the `docker` group can start a container as root. On this
machine that is the same as having root access.

## Local settings

Put anything that must not be shared in `~/.bashrc.local`: API tokens,
proxies, or paths that exist only on one machine. `shell/bashrc` loads that
file if it exists, and the bootstrap never changes it.

## Checking the result

`scripts/verify.sh` runs at the end of every bootstrap. Run it again at any
time. It reports every problem it finds, then exits with an error if any
check failed.
