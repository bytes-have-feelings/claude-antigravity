# claude-antigravity

A [Claude Code](https://docs.claude.com/en/docs/claude-code) **plugin** that lets Claude consult Google Gemini through the Antigravity CLI (`agy`) — for a second opinion, a fact-check, or a code review, or to convene an explicit multi-round **council** in which Claude and Gemini deliberate toward one answer.

POSIX `sh` wrappers around `agy`, with a zero-trust security prompt prepended to every call.

## Requirements

- **Claude Code** — the plugin host.
- **Antigravity CLI (`agy`)** — installed and on your `PATH`. Built and verified against agy v1.0.3.

24-bit color output is optional and honors `NO_COLOR`.

## Installation

This repo is a Claude Code plugin marketplace. Add it straight from GitHub, then install the plugin:

```
/plugin marketplace add bytes-have-feelings/claude-antigravity
/plugin install claude-antigravity
```

Or clone it and add the local path instead:

```sh
git clone https://github.com/bytes-have-feelings/claude-antigravity.git
```

```
/plugin marketplace add /absolute/path/to/claude-antigravity
/plugin install claude-antigravity
```

## Usage

### Consult — natural language

Ask Claude in plain language. Triggers include "ask gemini…", "second opinion from gemini…", "let gemini fact-check…", "gemini code review…". Claude sends your question to Gemini, prints the reply in purple, then cross-checks it as a peer and reconciles both into one answer.

For code review, embed a small diff inline (zero-trust, no setup); for a larger scope, point `agy` at a single directory with `--add-dir`.

### Council — explicit only

```
/claude-antigravity:council <topic> [N rounds]
```

Claude becomes the facilitator and convenes two members — a Claude member and a Gemini member — on the same task. They deliberate over N rounds (default 3) as a **consilium** (building on each other) or a **debate** (pressure-testing each other), driving toward the single most truthful answer. Each challenge targets fundamentals — flawed assumptions, wrong inferences, bad data — not nitpicks.

Council mode never auto-triggers; it runs only on the slash command or an explicit request ("convene a council on…", "debate this between claude and gemini…").

The facilitator narrates each round live (Claude orange, Gemini purple) and closes with a standardized synthesis: the converged result, any open points (each side in its own voice), and unresolved questions. The full transcript is saved under `./.claude-antigravity/council/`.

## How it works

Claude shells out to `agy` in headless print mode and treats Gemini as a **peer to reconcile with, never an oracle** — neither rubber-stamping its answer nor dismissing it. Every call is prefixed with a zero-trust security prompt (`references/security-prompt.md`), so fetched and internet content is handled as untrusted data, never as instructions.

**Consult** is one shot: `agy-consult.sh` asks Gemini, prints the reply, and Claude cross-checks the load-bearing claims before answering. **Council** is the facilitated version of the same idea, run over N rounds per `references/council-protocol.md` — both members get the identical task, each round is a fresh stateless prompt that relays the other's latest turn, and the facilitator closes with one synthesis.

Output is colored so the voices stay distinct: **Gemini purple, Claude orange, the council's converged result green**, facilitator text plain. Set `NO_COLOR` to disable color, and `AGY_PRINT_TIMEOUT` (default `300s`) to change the per-call timeout.

## License

[MIT](LICENSE).
