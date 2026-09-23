# How to work with the AI agents

This file is for you, not for the agents.

It lives at `~/.config/agents/HOWTO.md`. It stays after you delete the
bootstrap repository.

---

## What you have

| Thing | Where it is | What it does |
|---|---|---|
| `claude` | your shell | the agent you talk to |
| `@agent-investigator` | `~/.claude/agents/` | finds out what is true |
| `@agent-reviewer` | `~/.claude/agents/` | checks work it did not write. Has no shell and cannot edit |
| Your rules | `~/.config/agents/AGENTS.md` | how agents must behave, in every project |
| Spec template | `~/.config/agents/spec-template.md` | the shape of a plan |

---

## Talking to agents

You always talk to the main agent. Type `claude` and it starts.

The helpers are run by the main agent. They answer, then you are back with
the main agent. You never leave it.

Call a helper by name. The name always starts with `@agent-`:

```
@agent-investigator where does the code read the config file?
```

`@agent-` makes it run. Plain `@investigator` does not: that is how you
refer to a file.

To list your helpers:

```bash
ls ~/.claude/agents/
```

---

## The five steps

Use these for a change that is bigger than a few lines.

### Step 1. Find out what is true

```
@agent-investigator how does the cache work today, and what uses it?
```

It reads the code and reports what it found. It has no editing tools.

### Step 2. Write the plan

```
write .dev/cache-ttl/spec.md from ~/.config/agents/spec-template.md
```

`cache-ttl` is a short name for the work. Use one word or two.

For a bigger feature, make it ask you first:

```
I want to add a cache expiry time.
Interview me with the AskUserQuestion tool.
Ask about edge cases and trade-offs I have not thought of.
Then write .dev/cache-ttl/spec.md.
```

It asks about things you forgot. That is cheaper than finding them later.

### Step 3. Read the plan and approve it

Open the file. Read it. This step is you, not the agent.

Say "yes, build it" when the plan is right.

Say what is wrong when it is not. Do not let the agent start.

**Plan mode makes this a real gate.** Press `Shift` `Tab` until the bar
reads `plan mode on`. The agent can then read, but not write. It proposes a
plan and waits. Nothing changes until you accept.

Press `Ctrl` `G` to open the plan in your editor and change it yourself.

### Step 4. Build

Start a new session first. Type `/clear`. The plan is in a file, so nothing
is lost, and the agent starts with a clean head.

```
implement .dev/cache-ttl/spec.md
Run "uv run pytest" when you are done. Fix what fails. Repeat until it passes.
```

The second line matters more than the first. See the next section.

### Step 5. Review

```
@agent-reviewer check the changes against .dev/cache-ttl/spec.md.
Write .dev/cache-ttl/review.md
```

The reviewer did not write the code. It did not see why the code was
written that way. That is why it finds different problems.

Read the review. Fix what matters. Then commit.

---

## Skip steps for small work

A typo needs no plan. A one-line fix needs no review.

Use all five steps when the change is new behaviour, or when it is hard to
undo.

---

## Give it a way to check itself

This is the most useful habit on this page.

An agent stops when the work *looks* done. If it cannot test its own work,
then "looks done" is all it has. You become the test.

So give it a command that passes or fails:

```
Run "uv run pytest tests/test_cache.py" after each change.
Fix what fails. Repeat until it passes. Then show me the output.
```

Now the loop closes without you. The agent writes, runs, reads the result,
and tries again.

Anything with a pass or fail works:

| Kind of work | The check |
|---|---|
| A feature | the test you wrote in the spec |
| A bug fix | a test that fails now and passes after |
| A refactor | the whole test suite, unchanged |
| Style | `uv run ruff check .` |

Ask for the output, not for a summary. "Tests pass" is a claim. The output
is evidence.

---

## Keep the context small

The agent reads your whole conversation on every message. A long
conversation makes it slower, more expensive, and worse at its job.

Three commands:

```
/context     how full the window is now
/clear       throw the conversation away and start fresh
/compact     squash the conversation into a summary and carry on
```

When to use them:

- `/clear` whenever you change task. Finished the cache work, starting on
  the parser? Clear.
- `/clear` **after two failed corrections.** You told the agent twice and
  it is still wrong. The conversation is now full of wrong attempts.
  Start again, with a better first message.
- `/compact` when the work is long but still one task.

A fresh session with a good prompt beats a long session full of mistakes.

Give a session a name before you leave it, so you can find it again:

```
/rename cache-ttl
```

```bash
claude --continue    # carry on with the last session
claude --resume      # pick from a list
```

---

## Undo and try again

You can go back. This means you can try risky things.

| Keys | What it does |
|---|---|
| `Esc` | stop the agent now. The conversation is kept |
| `Esc` `Esc` | open the rewind menu |
| `/rewind` | the same menu |

The rewind menu puts the files **and** the conversation back to an earlier
point. So you can say "try the fast version", let it fail, and rewind.

One limit: rewind only tracks files the agent edited with its own tools. It
does not track files changed by a shell command. Commit often anyway.

---

## Write a better prompt

A vague prompt makes the agent read half the codebase to guess what you
meant. That is slow and expensive.

| Instead of | Say |
|---|---|
| add tests for cache.py | write a test for cache.py for the case where the key has expired. Do not use mocks |
| fix the login bug | login fails after the session times out. Look at src/auth/, especially token refresh. Write a failing test first, then fix it |
| why is this API strange? | read the git history of ExecutionFactory and tell me how its API got this way |
| add a widget | look at HotDogWidget.php first. Follow the same pattern. Use no new libraries |

Three habits:

- Name the file. Do not make it search.
- Say what "done" looks like.
- Point at an example in the code to copy.

Use `@` to attach a file to your message. The agent reads it before it
replies.

---

## Two sessions at once

Open a second terminal. Run `claude` in both.

The useful pairing is writer and reviewer:

| Terminal A | Terminal B |
|---|---|
| implement the cache expiry | |
| | review the cache expiry in @src/cache.py. Look for races and edge cases |
| here is the review: [paste]. Fix these | |

Terminal B never saw A's reasoning, so it judges the result on its own.

If both sessions will **edit** files, give each one its own checkout. Two
agents in one directory will overwrite each other:

```bash
claude --worktree cache-ttl
```

This makes a separate checkout on a new branch, and starts Claude in it.

It does more than `git worktree` on its own. Claude Code **refuses** any
edit to your main checkout from inside that session. It is a rule the tool
enforces, not a rule you ask the agent to follow. So it holds whatever
model you are on.

Two more things it does:

- It offers to clean up the checkout when you leave the session.
- It copies files named in `.worktreeinclude` into the new checkout. Put
  `.env` in there.

Run plain `claude` once in a repository before you use `--worktree` in it.
The first run asks you to trust the directory.

### Which one do I want?

| You want | Use |
|---|---|
| a side task that would fill this conversation with noise | a subagent: `@agent-investigator ...` |
| two changes to one repository at the same time | `claude --worktree <name>`, one per terminal |
| to hand a task off and check back later | `claude --bg "..."`, then `claude agents` |
| one session to tell another something | ask it: "tell the other session the migration finished" |

Each session costs full price. Two focused sessions beat five vague ones.

---

## The `.dev/` directory

`.dev/` holds your notes for work in progress. It lives inside the project:

```
~/personal/liken/.dev/
    cache-ttl/
        spec.md
        review.md
    faster-match/
        spec.md
```

One directory for each piece of work.

`ls .dev/` shows you what is in progress.

Git never sees `.dev/`. The bootstrap ignores it on this machine, for every
project. You do not add it to any `.gitignore`.

Move a plan into the project by hand when it is worth keeping.

---

## Adding an agent for one project

Put the file here:

```
~/personal/liken/.claude/agents/api-reviewer.md
```

It works in that project only.

A file looks like this:

```markdown
---
name: api-reviewer
description: Reviews the public API as a new user. Use for any change a user can call.
tools: Read, Grep, Glob
---

You are a skilled developer using this library for the first time.
You did not design it.

Ask:

1. Could I find this without being told it exists?
2. Does the name say what it does?
3. Is the default what most people want?
4. When I use it wrong, does the error tell me how to fix it?

Report each problem with the file and the line.
Do not change the code.
```

Two rules for the file:

- Set `tools:` to `Read, Grep, Glob` for a reviewer. It then has no way to
  change a file. Adding `Bash` gives it a shell. A shell can write files.
  So leave `Bash` out when you want the guarantee.
- Do not set `model:`. The agent then uses the model you are already on.

Put an agent in `~/.claude/agents/` instead when you want it everywhere.

---

## When to add an agent

Add one only when one of these is true:

- **It reads a lot.** You want the answer, not the reading. Example:
  `@agent-investigator`.
- **It must be independent.** It must not see why the code was written.
  Example: `@agent-reviewer`.
- **It must not edit.** You stop it with `tools:`, not with a request.

Do not add an agent for a different writing style. Ask the main agent
instead.

Each agent costs money to run. Two good agents beat five weak ones.

---

## Memory of past sessions

A plugin called `memsearch` records what you did in past sessions. It reads
them back when they are relevant.

You do not run it. It works on its own.

It stores everything on this machine, in `~/.memsearch/`. It sends nothing
away. It needs no API key.

To ask it something directly:

```
what did I decide about the cache last week?
```

To see what it costs you in context:

```bash
claude plugin details memsearch
```

To turn it off:

```bash
claude plugin disable memsearch
```

Each project also gets a small `.memsearch/` directory. Git never sees it.

---

## Which model am I using?

Claude Code shows the model at the bottom of the screen.

| Where you are | Model |
|---|---|
| `~/personal/...` | GLM 5.3 Flash, on OpenRouter |
| anywhere else | an Anthropic model |

To force the Anthropic model:

```bash
command claude
```

---

## A full example

```bash
cd ~/personal/liken
claude
```

```
@agent-investigator how are duplicate records found today?

write .dev/blocking-keys/spec.md from ~/.config/agents/spec-template.md.
The feature: only compare records that share a postcode.
```

Read the spec. Approve it. Then clear and build:

```
/clear

implement .dev/blocking-keys/spec.md
Run "uv run pytest" after each change. Fix what fails.
Repeat until it passes. Show me the output.
```

Then review:

```
@agent-reviewer check the changes against .dev/blocking-keys/spec.md.
Write .dev/blocking-keys/review.md
```

Then:

```bash
git add -A && git commit -m "feat: add blocking keys"
```

`.dev/` is not in the commit.
