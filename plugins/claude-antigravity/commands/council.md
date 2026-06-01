---
description: Convene a Claude + Gemini council — a consilium or a debate — that deliberates over N rounds and converges on the single most truthful answer (explicit-only).
argument-hint: <topic for the council> [N rounds]
---

The user has EXPLICITLY invoked council mode by running this command, so the explicit-confirmation gate is satisfied — proceed.

A council convenes a Claude member and a Gemini member on one shared task and drives them, over N rounds, toward the single most truthful answer — running as a **consilium** (building on each other) or a **debate** (pressure-testing each other) as the facilitator judges best. `references/council-protocol.md` is the source of truth for the spirit and the workflow.

**Run this via the `gemini-council` skill.** Invoke it now (via the Skill tool) so it resolves the plugin's bundled paths from its announced base directory and follows `references/council-protocol.md` exactly — do not locate the protocol or scripts relative to the current working directory yourself.

The topic/task for this council is:

$ARGUMENTS

Parse the round count from those arguments (e.g. "6 rounds"); default to 3 if none is given. Everything else is the task. Then facilitate per the skill and protocol.
