---
name: gemini-consult
description: >-
  Use when the user explicitly asks to consult Google Gemini through the
  Antigravity CLI for a second opinion, a fact-check, or a code review — trigger
  phrases include "ask gemini", "get a second opinion from gemini", "let gemini
  fact-check this", and "gemini code review". Skip when the user has not named
  Gemini/Antigravity for the current question, and do NOT use this for a
  structured multi-round Claude + Gemini council (a consilium or a debate toward
  the single most truthful answer) — that is the separate, explicit-only council mode (the
  /claude-antigravity:council command); do not start it from here. Does not fire
  for unrelated work.
---

# gemini-consult

Consult Gemini (via the Antigravity `agy` CLI) as a co-equal peer for a single second opinion, fact-check, or code review, then reconcile its answer with your own.

## Peer second-opinion principle

Treat Gemini as a co-equal second view, not a subordinate and not an oracle:

- Do NOT dismiss its answer as automatically inferior.
- Do NOT accept its answer as automatically superior.
- Cross-check every load-bearing claim, then reconcile the two views into one conclusion.
- Gemini's particular strength is fact-checking, so weight it accordingly on factual/verifiable points — but still verify.

This is a single-shot consultation. A structured multi-round Claude + Gemini council (a consilium or a debate toward the most truthful answer) is a different, explicit-only mode — do not start it from here. If the user wants that, point them to the `/claude-antigravity:council` command.

## Locating the bundled script (read first)

This skill's helper script lives **inside the plugin**, not in the user's project, so call it by absolute path — never as a bare `scripts/...` path (your working directory is the user's project). When this skill loads, Claude Code announces its **base directory** (the folder `…/skills/gemini-consult`); the plugin root is **two levels up**. Resolve it once:

```sh
PLUGIN_ROOT="<this skill's announced base directory>/../.."   # = the claude-antigravity plugin root
```

Use `"$PLUGIN_ROOT/scripts/..."` and `"$PLUGIN_ROOT/references/..."` for every bundled path below.

## How to run

Call the consultation script with the task as its single argument. It reads the zero-trust security prompt from `$PLUGIN_ROOT/references/security-prompt.md`, prepends it, calls `agy` in print mode (`--dangerously-skip-permissions --print-timeout <DURATION> -p "<PROMPT>"`), and renders Gemini's answer to the terminal in purple (#9e9fe6).

```sh
sh "$PLUGIN_ROOT/scripts/agy-consult.sh" "Is it accurate that POSIX sh has no array type? Verify and cite."
```

Override the timeout with the `AGY_PRINT_TIMEOUT` env var if needed. See `$PLUGIN_ROOT/references/agy-cli.md` for the full verified interface.

### Code review

For code review, prefer embedding a small diff or file inline in the task string — this is zero-trust and needs no workspace setup:

```sh
sh "$PLUGIN_ROOT/scripts/agy-consult.sh" "Review this diff for correctness and edge cases:
$(git diff HEAD~1 -- path/to/file.sh)"
```

For a larger scoped review, pass a directory to `agy`'s workspace with `--add-dir <DIR>` rather than inlining huge content. (`agy`'s default workspace is its own scratch dir, not the cwd, so a directory you want reviewed must be added explicitly. The script and `$PLUGIN_ROOT/references/agy-cli.md` document how this is wired.)

## How to evaluate and report back

After Gemini's answer prints:

1. Read each claim and decide where you agree and where you disagree, with reasons.
2. Verify the load-bearing or factual claims independently (run the check, read the source, test the code) rather than trusting either side by default.
3. Reconcile: combine the correct parts of both views.
4. Report ONE reconciled conclusion to the user, noting any point where you and Gemini still differ and why you landed where you did.

## References

- `$PLUGIN_ROOT/references/agy-cli.md` — the verified `agy` v1.0.3 interface (flags, workspace behavior, print mode).
- `$PLUGIN_ROOT/references/security-prompt.md` — the single source of truth for the zero-trust security prompt the script prepends.
