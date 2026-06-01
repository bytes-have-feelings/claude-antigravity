# The `agy` CLI interface (Antigravity)

This documents the **verified** interface of the Antigravity CLI binary `agy`,
version **1.0.3**, as confirmed by a live test. Treat this as ground truth.
Nothing here is invented; anything not verified is explicitly marked as an
assumption or as unverified.

## The one headless invocation we use

```sh
agy --dangerously-skip-permissions --print-timeout <DURATION> -p "<PROMPT>"
```

That is the single shape of call this plugin makes. Everything below explains
each piece and the constraints that make it work.

## `-p` ordering gotcha (read this first)

`-p` (also spelled `--print` or `--prompt`) is a **string flag**: it consumes
the **next token** as the prompt text.

Consequences, verified by live test:

- The prompt **must** come immediately after `-p`.
- `-p` **must be the last flag** on the command line.
- Putting `-p` before another flag makes `agy` treat that following flag string
  as the prompt itself (this is a confirmed failure mode, not a guess).

So always order the call as: all other flags first, then `-p`, then the prompt
string as the final argument. In scripts, pass the prompt as a single quoted
argument in the last position.

## `--dangerously-skip-permissions` (used **without** `--sandbox`)

`--dangerously-skip-permissions` auto-approves all tool requests so a headless
run never hangs waiting on an interactive permission prompt.

We deliberately use it **without** `--sandbox`. This is a considered user
decision: the facilitator (the main Claude agent) hands `agy` clear, scoped tasks
and reviews `agy`'s output before acting on it. The zero-trust security prompt
(see `references/security-prompt.md`) is prepended to every task to constrain
behavior at the prompt level rather than relying on a sandbox.

## `--print-timeout` and the `AGY_PRINT_TIMEOUT` env var

`--print-timeout` takes a **Go duration** string (e.g. `300s`, `5m`, `90s`).
Its built-in default is `5m0s`.

This plugin's default is `300s`, overridable via the environment variable
`AGY_PRINT_TIMEOUT`. Scripts should read `AGY_PRINT_TIMEOUT` and fall back to
`300s` when it is unset or empty.

Note: this plugin does **not** rely on any external `timeout(1)` command;
`agy`'s own `--print-timeout` is the only timeout mechanism we use.

## No `--model` flag

There is **no `--model` flag** in v1.0.3. The model that answers is whatever the
connected Antigravity subscription defaults to — currently the **Gemini Flash**
family.

Do not pass or fabricate a model flag. Model selection is configured in the
**Antigravity client**, not via the CLI. If a different model is desired, the
user changes it in the Antigravity client; this plugin cannot and does not
select a model.

## Workspace and `--add-dir`

`agy`'s **default workspace is `~/.gemini/antigravity-cli/scratch`**, **not** the
current working directory. This matters for code review: `agy` cannot see your
repo files just because you run it from inside the repo.

Two ways to give `agy` the code it needs to review:

1. **Inline (preferred for small diffs and zero-trust):** embed the code or diff
   directly inside the `-p` prompt text. Nothing on disk is exposed; `agy` sees
   only exactly what you paste.
2. **`--add-dir <DIR>` (for a larger scoped directory):** adds a directory to
   `agy`'s workspace. The flag is **repeatable** to add multiple directories.
   Use this when the review needs real files across a scoped subtree rather than
   a single inline diff.

Prefer inline for anything small; reach for `--add-dir` only when the task
genuinely needs file access to a bounded directory.

## Stateless re-prompting instead of `-c` / `--conversation`

`agy` offers conversation continuation: `-c` / `--continue` continues the most
recent conversation, and `--conversation <ID>` resumes a specific one by ID.

This plugin **deliberately does not use them.** Council rounds and other
multi-step interactions use **stateless re-prompting**: every round passes the
full needed context inside a fresh `-p` prompt. Rationale:

- It is more robust than juggling session state and conversation IDs.
- It works **identically for both council members** (the Gemini side via `agy`
  and the Claude-subagent side), so the protocol stays symmetric and predictable.
- The facilitator always controls exactly what each member sees each round, with
  no hidden carried-over state.

## Output format

In print mode, `agy`'s **stdout is the clean model response text** — no banner,
no ANSI chrome. **Exit code 0** on success. This means a script can capture
stdout directly as the answer and check the exit code for failure, without
stripping decoration.

## Truecolor rendering (ASSUMPTION, not a guarantee)

This plugin colors output with 24-bit ANSI truecolor sequences. Whether they
render depends on the terminal and on Claude Code passing the ANSI bytes
through. Many terminals advertise truecolor via `COLORTERM=truecolor`, but that
is not guaranteed to be set or forwarded.

Treat correct truecolor rendering as an **assumption**, not a guarantee. The
plugin honors the `NO_COLOR` convention (see `scripts/colorize.sh`): when
`NO_COLOR` is set and non-empty, output is emitted with no color codes. If
truecolor does not render in a given terminal, the text content is still fully
correct — only the coloring is affected.

## Quick reference

| Concern            | Verified fact                                                        |
| ------------------ | -------------------------------------------------------------------- |
| Headless call      | `agy --dangerously-skip-permissions --print-timeout <DUR> -p "..."`  |
| `-p` placement     | Last flag; prompt is the very next/last token                        |
| Sandbox            | Not used; rely on scoped tasks + zero-trust prompt + output review   |
| Timeout            | `--print-timeout` Go duration; default `300s`; env `AGY_PRINT_TIMEOUT` |
| Model selection    | No `--model` flag; chosen in the Antigravity client (Gemini Flash)   |
| Default workspace  | `~/.gemini/antigravity-cli/scratch` (NOT cwd)                         |
| Add files          | `--add-dir <DIR>`, repeatable                                        |
| Multi-turn         | Stateless re-prompting (we do NOT use `-c` / `--conversation`)       |
| stdout (print)     | Clean response text, no chrome; exit 0 on success                    |
| Color              | 24-bit ANSI; rendering is an assumption; `NO_COLOR` honored          |
