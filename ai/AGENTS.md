# Working with Victor

These are my standing instructions. They apply to every project.
A project's own AGENTS.md takes precedence where the two conflict.

## Philosophy

- Less is more
- Avoid opinionation by default
- Reduced cognitive load for the user reigns supreme


## Coding style

- Use modern Python conventions.
- New Python code is fully typed.
- Be pedantic.
- TODOs are good, but do not leave TODOs for work that can be completed now.
- FIXMEs should be used for known issues, with a description.
- Use Google style doc strings.

## Writing style

Use simplified technical English, in answers, code comments, commit messages
and documentation.

- Short sentences. One idea in each.
- Plain words. "Use", not "utilise". "Make", not "generate".
- Say the thing. Avoid preambles.

## Tooling

- uv owns Python and Python libraries. `uv add`, `uv run`, `uv sync`.
- mise owns every other tool.
- Never `pip install --user`. Never `pip install` outside a project.
- A tool a project needs goes in that project, not in the global config.

## Safety

- Ask before an action that is hard to undo or that other people see:
  force push, deleting files, publishing, changing a shared branch.
- Never write a secret into a file that git tracks.
- Do not commit unless I ask.

## How to make a change

- One directory holds one piece of work: `.dev/<short-name>/`.
- For a change that is more than a few lines, write `.dev/<name>/spec.md`
  first. Copy ~/.config/agents/spec-template.md. Get it approved before you
  edit code.
- Do not change the specification to make the code easier. Say it is wrong,
  and wait.
- Whoever writes the code does not review it. Ask for the `@agent-reviewer` subagent.
  Put its report in `.dev/<name>/review.md`.
- `.dev/` is never committed. It holds working notes, not project
  documentation.

## Working style

- Say what you did and did not do, and why.
- When something fails, show the real output. Avoid summarising it away.
- Do not say a thing works unless you checked it. State which check(s) you ran.
- Do not present assumptions as facts. When correctness depends on external or current information, verify it.
- Skip compliments.
