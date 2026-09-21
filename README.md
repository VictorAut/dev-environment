# dev-environment

A one-shot bootstrap for a fresh Ubuntu WSL environment.

Clone it, run it, and the machine is ready. You can then delete the
repository. The last step of the script offers to do that for you.

## Install

Use HTTPS for this first clone. The machine has no SSH key yet.

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/VictorAut/dev-environment.git ~/personal/dev-environment
cd ~/personal/dev-environment
./bootstrap.sh
```

The script asks you for your personal and work git identities, your GitHub
login in a browser, and whether you also want a work account. Everything
else runs without input.

Open a new shell when it finishes. Docker also needs a full WSL restart:
run `wsl --shutdown` in Windows PowerShell.

### Install the font first

Do this before you run the script, or the prompt will look broken.

The `powerbash10k` prompt draws arrows and icons. Those symbols come from
the font used by **Windows Terminal**, not from anything inside WSL. A
normal font shows them as empty boxes.

1. Download a patched font on Windows. For example
   [CaskaydiaCove Nerd Font](https://www.nerdfonts.com/font-downloads), or
   Cascadia Code PL, which ships with Windows Terminal.
2. Install it on Windows: select the `.ttf` files, right click, **Install**.
3. In Windows Terminal, open **Settings**, choose your Ubuntu profile, then
   **Appearance**, and set **Font face** to that font.

VS Code needs the same font for its own terminal. Set
`terminal.integrated.fontFamily` in your Windows VS Code settings.

## What it installs

| Item | Tool | Notes |
|---|---|---|
| System packages | apt | `curl`, `git`, `vim`, `unzip`, compilers |
| Tool manager | mise | in `~/.local/bin` |
| `uv`, `gh`, `node` | mise | installed globally, so they work everywhere |
| Build libraries | apt | so Python packages can compile from source |
| Python 3.10 to latest | uv | the version list is found at run time |
| Shell | oh-my-bash | theme `powerbash10k` |
| `~/.bashrc` | copied from `shell/bashrc` | the old file is kept as a backup |
| VS Code settings | copied from `vscode/` | machine settings and extensions |
| Docker | apt | Docker Engine, with systemd enabled in WSL |
| Git identities | git | different email in `~/personal` and `~/work` |
| SSH keys | ssh-keygen | one per GitHub account, no passphrase |
| Directories | | `~/work`, `~/personal` |

## Python

uv manages every Python version on this machine. mise does not.

```bash
uv python list                  # show the installed versions
uv run --python 3.12 script.py  # run with one version
uv venv --python 3.13           # create a virtual environment
uv init && uv add requests      # start a project
```

A project with a `pyproject.toml` needs no version flag. uv reads
`requires-python` and picks the right interpreter by itself.

## VS Code

VS Code runs on Windows and connects to WSL. Set it up once:

1. On Windows, install VS Code and its **WSL** extension
   (`ms-vscode-remote.remote-wsl`).
2. From a WSL shell, run `code .` in any directory. VS Code opens connected
   to WSL. You can also press `Ctrl+Shift+P` in VS Code and choose
   **WSL: Connect to WSL**.

The bootstrap writes your settings to `~/.vscode-server/data/Machine/`. It
also installs the extensions in `vscode/extensions.txt`, if the `code`
command is available. On a brand new machine it is not, because it comes
from the Windows side. In that case, connect once as above, then run
`scripts/install-vscode.sh` again.

## Git identities

Git chooses your name and email from the location of the repository:

| Location | Identity |
|---|---|
| `~/personal/...` | personal |
| `~/work/...` | work |
| anywhere else | personal |

The bootstrap asks for both identities and writes them to
`~/.gitconfig-personal` and `~/.gitconfig-work`. `~/.gitconfig` then points
at them with `includeIf` rules. You never set an identity per repository.

Check which one a repository uses:

```bash
git config user.email
```

Change an identity later by editing the two files. The rules stay the same.

## Docker

Docker Engine runs inside WSL. You do not need Docker Desktop.

Two settings need a full WSL restart before they take effect: systemd, which
starts the docker service, and your membership of the `docker` group, which
lets you run docker without `sudo`. So after the bootstrap:

```powershell
wsl --shutdown
```

Open WSL again, then check it works:

```bash
docker run --rm hello-world
```

Note: a member of the `docker` group can start a container as root. On this
machine that is the same as having root access.

## Cloning your own repositories

You have two GitHub accounts, so each one gets its own key and its own host
name. Replace `github.com` in any URL you copy from the website:

```bash
git clone git@github-personal:VictorAut/some-repo.git
git clone git@github-work:some-org/some-repo.git
```

A plain `github.com` URL may use the wrong key, and GitHub will then treat
you as the wrong user.

## Local settings

Put anything that must not be shared in `~/.bashrc.local`: API tokens,
proxies, or paths that exist only on one machine. `shell/bashrc` loads that
file if it exists, and the bootstrap never changes it.
