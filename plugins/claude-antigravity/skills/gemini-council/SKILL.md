---
name: gemini-council
description: >-
  Use when the user EXPLICITLY asks to convene a council of Claude and Gemini —
  a consilium or a debate — to deliberate over multiple rounds toward the single
  most truthful answer. Trigger phrases include "convene a council", "run a
  council", "start council mode", "convene a consilium on ...", "debate this
  between claude and gemini", "have claude and gemini debate ...", "council
  between claude and gemini on ...", "have claude and gemini deliberate together
  on ...", "hold a council on ...", plus the /claude-antigravity:council command.
  NEVER use this for a general second opinion, a fact-check, or a code review
  (that is the separate gemini-consult mode), and NEVER trigger it as a side
  effect of unrelated work — it runs only on an explicit council/debate request
  this turn.
---

# gemini-council

A council convenes two expert members — a Claude member and a Gemini member — on one shared task and drives them toward the single most truthful answer. It runs as a **consilium** (colleagues building on each other's reasoning), a **debate** (each pressure-testing the other to expose fundamental errors), or a blend — the facilitator picks the stance that most efficiently reaches the truth, honoring any stance the user names. Whichever stance, the aim is the truth, never winning: challenges target fundamentals — flawed assumptions, wrong inferences, bad or misread data, conclusions that do not follow — and never nitpick small or cosmetic points. The protocol (`references/council-protocol.md`) is the single source of truth for how this runs.

## Explicit-confirmation gate (read first)

Proceed ONLY if the user explicitly requested a council this turn (via one of the trigger phrases above or the `/claude-antigravity:council` command). If this skill activated during unrelated work — a general question, a normal second opinion, a code review, or any task where the user did not explicitly ask to convene a council — STOP and do nothing. Do not convene anything, do not call any script, do not produce a transcript. A council never auto-triggers.

## Locating the bundled files

The protocol and scripts live **inside the plugin**, not in the user's project. When this skill loads, Claude Code announces its **base directory** (the folder `…/skills/gemini-council`); the plugin root is **two levels up**. Resolve it once and use it for every bundled path — never a bare `references/...` or `scripts/...` path (your working directory is the user's project):

```sh
PLUGIN_ROOT="<this skill's announced base directory>/../.."   # = the claude-antigravity plugin root
```

## How to facilitate

With the gate satisfied, you are the FACILITATOR (the chair) of the council. Read `$PLUGIN_ROOT/references/council-protocol.md` and follow it exactly. Pass it:

- the task/topic the user gave, and
- the requested round count if the user named one (e.g. "6 rounds"); otherwise default to 3 rounds.

The protocol is the single source of truth for how the council runs: convening both members on the identical task, relaying each member's contribution to the other with truth-seeking framing, the round loop, the per-role color display, the saved transcript, and the closing council synthesis. It references the bundled scripts and the security prompt as `$PLUGIN_ROOT/scripts/...` and `$PLUGIN_ROOT/references/...`; follow it rather than improvising the workflow here.

## References

- `$PLUGIN_ROOT/references/council-protocol.md` — the single source of truth for the council workflow (facilitator role, rounds, consilium/debate stance selection, truth-seeking relay framing, display colors, transcript, synthesis).
- `$PLUGIN_ROOT/references/security-prompt.md` — the zero-trust security prompt; both members receive it (the script prepends it for the Gemini side, and the protocol hands it to the Claude member explicitly).
