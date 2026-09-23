# dev-environment

This repository sets up a new Ubuntu WSL machine.

[mise.toml](mise.toml) declares the machine. `mise bootstrap` applies it.
Five steps need a terminal, so they stay as scripts in [scripts/](scripts/).

You never clone this repository yourself. mise clones it to
`~/.local/share/mise/bootstrap-repo`. Everything it installs keeps working
without it.

---

## 1. Install a font first

Do this before you install. If you skip it, the prompt shows empty boxes.

The prompt draws arrows and icons. These are not letters. They are pictures
inside a font. **Windows** chooses the font, so nothing inside WSL can fix a
missing picture.

You need a **Nerd Font**. A Nerd Font is a normal font with about 9,000
pictures added.

1. Download a font from [nerdfonts.com](https://www.nerdfonts.com/font-downloads).
   Use `CaskaydiaCove Nerd Font`.
2. Unzip it.
3. Select the `.ttf` files. Right click. Choose **Install for all users**.
   Skip the files named `Windows Compatible`.
4. Open Windows Terminal. Press `Ctrl` `,`.
5. Choose your **Ubuntu** profile, then **Appearance**.
6. Set **Font face** to the font. Use the name in the list. Some downloads
   install as `CaskaydiaCove NF`.

To set the font for every profile at once, press `Ctrl` `Shift` `,` and add a
`defaults` block. Leave the `list` block as it is.

```json
{
    "profiles": {
        "defaults": {
            "font": { "face": "CaskaydiaCove Nerd Font", "size": 11 },
            "colorScheme": "One Half Dark"
        }
    }
}
```

VS Code has its own font setting. Set it too:

```json
"terminal.integrated.fontFamily": "CaskaydiaCove Nerd Font"
```

### Check the font

```bash
echo -e "     "
```

You should see six pictures. Boxes mean the font is wrong. The usual cause is
a wrong name, or the `Mono` or `Propo` variant.

---

## 2. Install

Run two commands:

```bash
curl -fsSL https://mise.run | sh
~/.local/bin/mise bootstrap \
    --from https://github.com/VictorAut/dev-environment.git \
    --yes
```

| Flag | What it does |
|---|---|
| `--from` | clones this repository into mise's own directory. Your home directory stays clean |
| `--yes` | answers yes to every question mise asks |

Add `--dry-run` to see the plan and change nothing.

**To run it a second time, add `--update`.** Without it, mise reuses the
copy it cloned the first time. It will not see anything you pushed since.

You need **mise 2026.9.12 or newer**. The `curl` line installs the newest
version, so a new machine is always fine. On an old machine, run
`mise self-update`. An old mise stops with a clear message.

Stay at the keyboard. The bootstrap asks you six things:

1. Your **sudo password**, for apt.
2. Your personal git name and email.
3. Your work git name and email. Press Enter twice to skip.
4. Your GitHub login, in a browser.
5. Whether to set up a work GitHub account too.
6. Whether to log in to OpenRouter now.

Everything else runs without input.

Open a new shell when it finishes.

---

## 3. What it installs

| Item | Declared in | Notes |
|---|---|---|
| `curl`, `git`, `vim`, `unzip`, compilers | `[bootstrap.packages]` | no `-dev` libraries. Add one when a build asks for it |
| tmux | `[bootstrap.packages]` | keeps shells and servers alive when you close the terminal |
| `~/.tmux.conf` | `[dotfiles]` | copied from `tmux/tmux.conf` |
| oh-my-bash | `[bootstrap.repos]` | theme `powerbash10k` |
| `~/.bashrc` | `[dotfiles]` | copied from `shell/bashrc` |
| Global mise config | `[dotfiles]` | copied from `mise/global-config.toml` |
| VS Code settings | `[dotfiles]` | copied from `vscode/settings.json` |
| `uv`, `gh` | `[tools]` | |
| Claude Code, Codex, `ori` | `[tools]` | AI agents |
| Agent instructions | `[dotfiles]` | one file, read by both agents |
| `investigator`, `reviewer` | `[dotfiles]` | Claude Code subagents, in every project |
| How to use the agents | `[dotfiles]` | `~/.config/agents/HOWTO.md`, written for you |
| memsearch | `scripts/setup-ai.sh` | remembers past sessions. Local, no API key |
| Python 3.10 to newest | `scripts/install-pythons.sh` | the list is read from uv at run time |
| Git identities | `scripts/setup-git.sh` | one email in `~/personal`, another in `~/work` |
| SSH keys | `scripts/setup-ssh.sh` | one key for each GitHub account |
| wslu | `scripts/setup-ssh.sh` | opens a Windows browser. Skipped when the release has no such package |
| VS Code extensions | `scripts/install-vscode.sh` | from `vscode/extensions.txt` |

### Why five steps are scripts

`mise bootstrap` reads a file. These five cannot:

| Step | Why |
|---|---|
| Python | it asks uv which versions exist, while it runs |
| Git identities | it asks you questions |
| SSH keys | it opens a browser, and asks GitHub for a token |
| AI agents | it links files and logs in to OpenRouter |
| VS Code extensions | it needs the `code` command, which may not exist yet |

---

## 4. Which tool owns what

One rule. Follow it and the two tools never fight.

| You need | Use | Recorded in |
|---|---|---|
| A Python version | uv | `.python-version`, `pyproject.toml` |
| Python libraries | uv | `pyproject.toml`, `uv.lock` |
| Any other tool | mise | `mise.toml` in the project |
| A command you want everywhere | mise, global | `~/.config/mise/config.toml` |
| A Python command you want everywhere | `uv tool` | its own environment |

Do not install a project's tools globally. Your machine would then differ
from CI and from other people.

Both tools have good documentation: [uv](https://docs.astral.sh/uv/) and
[mise](https://mise.jdx.dev/).

---

## 5. AI agents

Claude Code is the default agent. Codex is installed next to it.

### Which model runs where

| Where you are | What `claude` runs |
|---|---|
| `~/personal/...` | GLM 5.3 Flash, on OpenRouter |
| anywhere else | an Anthropic model |

A small function in `~/.bashrc` does this. Inside `~/personal` it calls `ori`,
which is OpenRouter's launcher. `ori` starts the same Claude Code with
OpenRouter settings, for that run only. Nothing else changes.

```bash
claude            # picks the model from the directory
command claude    # forces the Anthropic model, anywhere
```

Claude Code names its model in its own footer. `/status` shows more.

Change the personal model in one place, in `~/.bashrc`:

```bash
export AI_PERSONAL_MODEL="z-ai/glm-5.3-flash"
```

GLM 5.3 Flash is small and cheap. If it loops or misuses tools, try
`z-ai/glm-5.3`. Set a spending limit on your key at
[openrouter.ai/settings/keys](https://openrouter.ai/settings/keys). An agent
in a loop spends fast.

### Codex

Codex has no per-directory setting. Choose the model when you start it:

```bash
codex                                    # the OpenAI default
ori codex --model "$AI_PERSONAL_MODEL"   # GLM, on OpenRouter
```

### Instructions for both agents

One file holds your standing instructions:

```
~/.config/agents/AGENTS.md     the file, copied from ai/AGENTS.md
~/.claude/CLAUDE.md    -> it   link
~/.codex/AGENTS.md     -> it   link
```

Edit the file. Both agents change. Keep it short. Every line is read at the
start of every session.

For rules that belong to one project, put an `AGENTS.md` in that repository.
Both agents read it. It wins where it disagrees with the file above.

### How to make a change

The workflow is small on purpose. It rests on two subagents, not on a
process document. A subagent runs in its own context window, and Claude Code
enforces its tool list. Neither depends on the model, so both work the same
on GLM as on Claude.

| Step | What you do |
|---|---|
| 1. Understand | `@agent-investigator` finds out what is true |
| 2. Specify | write `.dev/<name>/spec.md` from `~/.config/agents/spec-template.md` |
| 3. Approve | read the spec. Nothing is built until you do |
| 4. Build | the main session writes the code |
| 5. Review | `@agent-reviewer` checks it, and writes `.dev/<name>/review.md` |

The full guide, with commands you can copy, lives on the machine itself:
`~/.config/agents/HOWTO.md`. It stays after you delete this repository.

Step 5 is the part that pays. The reviewer never saw the author's reasoning,
so it cannot inherit the author's blind spots. That costs nothing to set up.

Skip steps for a small change. A one-line fix does not need a specification.

### Where the notes live

`.dev/<name>/` holds the notes for one piece of work. One directory for
each. They sit next to the code, because that is where an agent reads.

```
.dev/
    parquet-backend/       one piece of work
        spec.md
        review.md
    fuzzy-match-speed/     another, not started yet
        spec.md
```

It is never committed. The bootstrap adds `.dev/` to your **global** git
ignore file, so no project's `.gitignore` has to mention it:

```bash
git config --global core.excludesFile   # ~/.config/git/ignore
```

Move a specification into the repository by hand when it is worth keeping as
project history.

### One thing to know

Anthropic does not support Claude Code on models that are not Claude. It
works, and many people do it, but Anthropic does not test it. Expect a
problem now and then in `~/personal`. An OpenRouter model also means that
session does not use your Claude subscription.

If it breaks, type `command claude`. You are back on a supported setup.

---

## 6. Git identities

Git picks your name and email from the location of the repository:

| Location | Identity |
|---|---|
| `~/personal/...` | personal |
| `~/work/...` | work |
| anywhere else | personal |

The bootstrap writes `~/.gitconfig-personal` and `~/.gitconfig-work`.
`~/.gitconfig` points at them with `includeIf` rules. You never set an
identity for one repository.

To see which one a repository uses:

```bash
git config user.email
```

---

## 7. Clone your own repositories

You have two GitHub accounts. Each one has its own key and its own host name.
Change `github.com` in any address you copy from the website:

```bash
git clone git@github-personal:VictorAut/some-repo.git
git clone git@github-work:some-org/some-repo.git
```

A plain `github.com` address may use the wrong key. GitHub then treats you as
the wrong user.

---

## 8. VS Code

VS Code runs on Windows. It connects to WSL.

1. On Windows, install VS Code and its **WSL** extension
   (`ms-vscode-remote.remote-wsl`).
2. In a WSL shell, run `code .`. VS Code opens, connected to WSL.

mise copies your settings to `~/.vscode-server/data/Machine/settings.json`.

Extensions need the `code` command. That command comes from Windows, so a new
machine does not have it yet. The bootstrap skips them.

Connect once, as above. Then run:

```bash
~/.local/share/mise/bootstrap-repo/scripts/install-vscode.sh
```

The list it reads is also copied to `~/.config/vscode-extensions.txt`, so
the script still works if that directory is gone.

---

## 9. When you need Docker

Docker is not installed. Most projects do not need it. Install it on the day
you do:

```bash
# Add the Docker package repository.
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) \
signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && \
echo "$VERSION_CODENAME") stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

# Install it.
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# Start it without sudo, and start it at boot.
printf '\n[boot]\nsystemd=true\n' | sudo tee -a /etc/wsl.conf
sudo usermod -aG docker "$USER"
```

Then run `wsl --shutdown` in Windows PowerShell. Open WSL again and test it:

```bash
docker run --rm hello-world
```

A member of the `docker` group can start a container as root. On this machine
that equals root access.

---

## 10. Settings for one machine only

Put anything you must not share in `~/.bashrc.local`. For example: API
tokens, proxies, paths that exist on one machine. `shell/bashrc` loads that
file. The bootstrap never changes it.

Every other copied file is **replaced** each time the bootstrap runs, with
no backup: `~/.bashrc`, `~/.config/mise/config.toml`, the agent
instructions and the VS Code settings. Edit those in the repository, or in
`~/.bashrc.local`.

---

## 11. Check the machine

`scripts/verify.sh` runs at the end of every bootstrap. Run it again with:

```bash
~/.local/share/mise/bootstrap-repo/scripts/verify.sh
```
 It reports every problem, then exits with an error if a check failed.
