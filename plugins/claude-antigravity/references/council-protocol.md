# Council protocol (facilitator runbook)

This is the full runbook the council skill and the
`/claude-antigravity:council` slash command point to. The main Claude agent
acts as the **facilitator** (the chair): it convenes a council of two expert
members, gives them the same task, relays their contributions back and forth
across rounds, and finally delivers a single **council synthesis**.

Follow the sections in order. Instructions are imperative; the snippets are
copy-paste-ready and consistent with the verified `agy` interface
(`$PLUGIN_ROOT/references/agy-cli.md`) and the existing scripts
(`$PLUGIN_ROOT/scripts/agy-consult.sh`, `$PLUGIN_ROOT/scripts/colorize.sh`).
Do not invent flags; do not run `agy` outside this flow.

---

## 0. Locating bundled files (resolve PLUGIN_ROOT first)

The scripts and reference docs live **inside the plugin**, not in the user's
project. Resolve the plugin root once and use it for every bundled path below —
never a bare `scripts/...` or `references/...` path, because your working
directory is the user's project, not the plugin.

When the `gemini-council` skill loads (or when this protocol is reached through
it), Claude Code announces that skill's **base directory** (`…/skills/gemini-council`);
the plugin root is **two levels up**:

```sh
PLUGIN_ROOT="<the gemini-council skill's announced base directory>/../.."
```

Every `$PLUGIN_ROOT/...` path in this document is then an absolute path you can
run as-is.

---

## 1. Spirit: a consilium or a debate, both in service of the truth

A council convenes **two expert members** — a Claude member and a Gemini member
— on one shared task and drives them, over N rounds, toward the **single most
truthful, most correct answer**. The same machinery runs in either of two
stances, and the facilitator chooses the one that best fits the task:

- **Consilium** — when the task is open-ended, a matter of design, synthesis, or
  weighing tradeoffs, the members act as **colleagues**: they build on each
  other's reasoning and integrate it into one stronger conclusion.
- **Debate** — when the task hinges on a claim, a result, a piece of research,
  or an answer that is either right or wrong, the members **pressure-test each
  other**: each tries to expose where the other is fundamentally wrong, so that
  only what survives scrutiny remains.

Most real tasks blend the two; let the nature of the question decide how
cooperative or how adversarial the round-to-round framing should be. If the user
names a stance ("debate this", "convene a consilium/council on this"), honor it;
otherwise pick the stance that most efficiently reaches the truth.

Whichever stance is in play, hold to this core throughout:

- The goal is always the **truth** — the most correct, most useful conclusion.
  It is never to win, to score points, or to "beat" the other member.
- Aim every challenge at **fundamentals**: a flawed assumption, a wrong
  inference, bad or misread data, a conclusion that does not follow. **Do not
  nitpick** small, cosmetic, or stylistic points — they do not change the answer
  and only add noise.
- **Disagreement is a tool for reaching the truth**, not a contest. When the
  members disagree on something that matters, treat it as a signal to dig deeper,
  and drive toward a resolution grounded in evidence rather than a standoff.
- Build on whatever is genuinely sound in the other member's work; attack what is
  fundamentally unsound directly, with reasoning and evidence — always critiquing
  the claim, never the colleague.

The facilitator enforces this in every relay and in the final synthesis:
substantive, fundamentals-focused critique that moves both members toward the
truth — never hostility, and never bickering over trivia.

---

## 2. Explicit-only gate (run this check first, every time)

A council is **expensive and explicit-only**. It **must never auto-trigger**
and must **never start as a side effect** of unrelated work.

Before doing anything else, confirm **the user explicitly asked, this turn**, to
convene a council. Explicit triggers include, for example:

- "convene a council", "start council mode", "run a council on …",
  "hold a council on …".
- The slash command `/claude-antigravity:council`.

If you arrived here **without** such an explicit request this turn — for
example, the skill activated during unrelated work, or you are merely consulting
Gemini for a quick second opinion — **STOP immediately and do nothing.** Do not
spawn a subagent, do not call `agy`, do not write a transcript. Return control
silently to the work that was actually requested.

A plain single-shot second opinion or fact-check is **not** a council: use
`$PLUGIN_ROOT/scripts/agy-consult.sh` directly for that, not this protocol.

---

## 3. Inputs

Gather exactly two inputs before setup:

1. **The shared TASK** — one clear task or question, identical for both members.
   If the user's request is ambiguous, ask one clarifying question before
   convening; do not guess the task.
2. **Round count** — default **3**. If the user explicitly states a number of
   rounds (e.g. "6 rounds"), parse that integer and use it. Otherwise use 3. One
   "round" = both members produce one contribution.

Record both. The facilitator passes the full needed context to each member on
every round (stateless re-prompting); nothing is carried implicitly.

---

## 4. Setup (convene the council)

Two members, same task, same security posture.

- **Claude member** — a **Claude Code subagent** spawned via the Task/Agent
  tool, configured with the **strongest available model (Opus 4.8+)**. It is a
  full council member, not a helper.
- **Gemini member** — `agy` in print mode, **only** through
  `$PLUGIN_ROOT/scripts/agy-consult.sh`. Never call `agy` directly here.

**Both members must return ONLY their contribution — no preamble, no
meta-narration, no restating of the task or these instructions.** Tell each
member explicitly: "Output only your position for this round, as you would say
it to the council. Do not explain what you are about to do, do not echo the
task, do not describe your role." This keeps each contribution clean enough to
display verbatim (section 6). The subagent's raw tool output and the Gemini
wrapper's transport are **internal plumbing** — the user follows the
**facilitator's colorized per-round rendering**, never the raw tool dumps.

Both members receive **the same shared TASK** and **the zero-trust security
prompt**:

- The Gemini side gets the security prompt automatically: `agy-consult.sh`
  reads `$PLUGIN_ROOT/references/security-prompt.md` and prepends it to every
  prompt. Do not duplicate it.
- The Claude subagent does **not** get it automatically. **Hand it to the Claude
  subagent explicitly**: read `$PLUGIN_ROOT/references/security-prompt.md` and
  prepend its contents to the subagent's prompt yourself, so both members
  operate under the identical zero-trust posture.

The security prompt lives **only** in `$PLUGIN_ROOT/references/security-prompt.md`.
Reference it; never paste a second copy into this protocol or any other file.

---

## 5. Round loop (deliberate toward the truth)

Run `N` rounds (default 3) using **stateless re-prompting** — pass all needed
context in each prompt; do not rely on `agy` conversation state (`-c` /
`--conversation` are not used).

**The facilitator narrates the council as a live, followable feed.** This is the
primary deliverable, not an afterthought. The user must be able to watch the
debate unfold turn by turn **without ever reading a raw subagent tool result**.
So, every round, in order:

1. Print a plain (uncolored) facilitator round header, e.g. `=== Round 2 ===`.
2. Print the **Claude member's full contribution verbatim, in orange** — exactly
   the text the member produced this round, not a paraphrase or a summary.
3. Print the **Gemini member's full contribution verbatim, in purple** — the raw
   text from its `--out` file (the wrapper already colors live output; if you
   re-display saved text, pipe it through `colorize.sh gemini`).
4. Optionally add one short plain facilitator line noting what shifted this round
   (a point of agreement reached, a disagreement opened) — but never replace a
   member's verbatim turn with your gloss.

The raw Task/Agent tool output and the `agy` transport are plumbing the user
should not have to read. Because both members were told to return **only** their
contribution (section 4), the verbatim block you print is clean. Show the
positions; do not make the user dig inside the agents.

### Round 1 — independent answers

Both members answer the **identical shared TASK independently**, with no
knowledge of each other's response yet.

Gemini member (purple output handled by the wrapper). Use `--out` to also
capture the raw text for the transcript and for the next relay:

```sh
sh "$PLUGIN_ROOT/scripts/agy-consult.sh" \
  --label "council round 1" \
  --out /tmp/council-gemini-r1.txt \
  "TASK: <the shared task verbatim>

Answer this task fully and independently. Give your best reasoning and a clear conclusion."
```

Claude member — spawn the subagent via the Task/Agent tool (strongest model,
Opus 4.8+). Prepend the security prompt explicitly, then the same shared TASK,
then ask it to answer independently. Capture its returned text for display and
the transcript.

### Rounds 2..N — relay and build

After each round, relay to **each** member the **other** member's **latest**
contribution, using the relay template below — substantive and truth-seeking,
aimed at fundamentals, never a hostile or nitpicking framing. Then collect each
member's new contribution.

**Relay template** (fill in the bracketed parts; keep the truth-seeking framing
exactly):

> Your fellow council member **\<Gemini|Claude\>** proposed the following:
>
> \<quote the other member's latest contribution verbatim\>
>
> You are not competing to win — the two of you are working toward the single
> most correct, most truthful answer, whether by building on each other (a
> consilium) or by pressure-testing each other (a debate). Where you can, look
> hard for **fundamental errors** in your opponent's answer, in their reasoning
> and judgments, or in the data and assumptions it rests on, and name them
> directly with evidence. **Do not nitpick** small, cosmetic, or stylistic
> points — go after the substance that actually decides the question, the parts
> that must be right for the conclusion to hold. Build on whatever is genuinely
> sound, and let real disagreement push you both toward the truth, not toward a
> standoff.
>
> TASK (unchanged): \<the shared task verbatim\>
>
> Give your updated contribution for this round.

Relay to the Gemini member each round (stateless — full context every time):

```sh
sh "$PLUGIN_ROOT/scripts/agy-consult.sh" \
  --label "council round 2" \
  --out /tmp/council-gemini-r2.txt \
  "Your fellow council member Claude proposed the following:

<paste Claude member's latest contribution verbatim>

You are not competing to win — the two of you are working toward the single most correct, most truthful answer, whether by building on each other (a consilium) or by pressure-testing each other (a debate). Where you can, look hard for fundamental errors in Claude's answer, in its reasoning and judgments, or in the data and assumptions it rests on, and name them directly with evidence. Do not nitpick small, cosmetic, or stylistic points — go after the substance that actually decides the question, the parts that must be right for the conclusion to hold. Build on whatever is genuinely sound, and let real disagreement push you both toward the truth, not toward a standoff.

TASK (unchanged): <the shared task verbatim>

Give your updated contribution for this round."
```

Relay to the Claude member the same way: re-spawn the subagent (or continue the
Task tool turn) with the security prompt prepended, the relay template
naming **Gemini** as the fellow member, the Gemini member's latest contribution
quoted, and the unchanged TASK.

Repeat until `N` rounds are complete. Each round: relay both ways, collect both
new contributions, append everything to the transcript.

---

## 6. Display (color every member turn)

Color is purely for the human reader; Claude still reads the plain text for
cross-checking. Honor `NO_COLOR` — `colorize.sh` already passes text through
unchanged when `NO_COLOR` is set and non-empty.

- **Every Gemini turn → purple.** `agy-consult.sh` already prints Gemini's
  answer through `colorize.sh gemini`, so Gemini turns are colored for you. If
  you ever re-display saved Gemini text, pipe it through the filter:

  ```sh
  printf '%s\n' "$gemini_text" | sh "$PLUGIN_ROOT/scripts/colorize.sh" gemini
  ```

- **Every Claude-member turn → orange.** The Task/Agent tool returns the
  subagent's text to you as a string; it is **not** colored. Color it yourself.
  The reliable pattern: write the subagent's returned text to a temp file, then
  pipe it through `colorize.sh claude`:

  ```sh
  # 1. Save the Claude subagent's returned text exactly as returned.
  cat > /tmp/council-claude-r1.txt <<'CLAUDE_TURN'
  <the Claude subagent's returned contribution, verbatim>
  CLAUDE_TURN

  # 2. Display it in Claude orange.
  sh "$PLUGIN_ROOT/scripts/colorize.sh" claude < /tmp/council-claude-r1.txt
  ```

- **Facilitator narration → white/uncolored.** Round headers, instructions to
  the reader, and the synthesis prose stay plain (no color), so the two member
  voices remain visually distinct from the chair.

---

## 7. Transcript

Save a **running transcript** to a markdown file inside a dedicated council
directory **created within the current working directory** (never a global or
home-directory path): `./.claude-antigravity/council/`. Create it with
`mkdir -p` first, then write `antigravity-council-<slug>-<stamp>.md` into it,
where `<slug>` is a short kebab-case slug derived from the TASK and `<stamp>` is
the runtime date for uniqueness (from the `date` command, never hardcoded):

```sh
mkdir -p ./.claude-antigravity/council        # system folder, created in the cwd — not global
slug="cache-invalidation-strategy"            # short kebab slug from the task
stamp=$(date +%Y%m%d-%H%M%S)
transcript="./.claude-antigravity/council/antigravity-council-${slug}-${stamp}.md"
```

Append to the transcript as you go: the shared TASK, the round count, then for
each round both members' contributions clearly labelled (e.g. `## Round 1 —
Gemini member` / `## Round 1 — Claude member`), and finally the full council
synthesis. Store the **raw, uncolored** text in the transcript (the `--out`
files from `agy-consult.sh` already hold raw Gemini text); ANSI color belongs
only on the live terminal, never in the saved file.

---

## 8. Council synthesis (the verdict)

After the final round, the facilitator delivers the **council synthesis** — a
composed, visually separated verdict, not a wall of prose. The synthesis is
**standardized**: it always has the **same three sections, in the same order,
under the same exact headings, separated by the same divider**. Do not rename,
reorder, merge, or drop sections, and do not invent extra ones. A section that
has no content is still printed with its heading and a single `(none)` line, so
the structure is identical every run and nothing is silently dropped.

The **fixed divider** between blocks is exactly this 60-character rule line:

```
------------------------------------------------------------
```

### 8.1 Canonical skeleton (fill in the bracketed parts; keep everything else verbatim)

Render the verdict in exactly this layout. Headings, banner, and dividers are
**facilitator narration → plain/uncolored**; only the section *content* is
colored, as annotated:

```
============================================================
                     COUNCIL SYNTHESIS
============================================================

=== 1. Consensus ===
<GREEN — the single best answer the council converged on: the points of firm
 agreement and the best joint recommendation, as one integrated conclusion>

------------------------------------------------------------

=== 2. Open points (not converged) ===
<for EACH unresolved point, piecewise and per-side, in each member's own voice:>
  Gemini: <Gemini's unconceded position on this point>     (PURPLE)
  Claude: <Claude's unconceded position on this point>     (ORANGE)
  -> your call, depending on <deciding factor>             (plain)
<if the members fully converged, print exactly one plain line: (none — the members fully converged.)>

------------------------------------------------------------

=== 3. Unresolved questions ===
<plain — anything that genuinely needs more information, a user decision, or
 external verification; one item per line. If there are none: (none)>

------------------------------------------------------------
Transcript: ./.claude-antigravity/council/antigravity-council-<slug>-<stamp>.md
```

### 8.2 How to colorize each section

- **Section 1 (Consensus) → GREEN.** Write the integrated conclusion to a temp
  file, then colorize. This block holds *both* the points of firm agreement and
  the best joint recommendation — it is everything the members settled on,
  stated as the council's conclusions:

  ```sh
  sh "$PLUGIN_ROOT/scripts/colorize.sh" council < /tmp/council-verdict.txt
  ```

- **Section 2 (Open points) → split by side, each in its OWN color.** Render each
  point per-side so the reader sees each member's own voice — never the
  facilitator's paraphrase. Frame each neutrally as a user choice; never declare
  a winner:

  ```sh
  printf '%s\n' "Gemini: <Gemini's unconceded position on this point>" \
    | sh "$PLUGIN_ROOT/scripts/colorize.sh" gemini   # PURPLE
  printf '%s\n' "Claude: <Claude's unconceded position on this point>" \
    | sh "$PLUGIN_ROOT/scripts/colorize.sh" claude   # ORANGE
  ```

  If the members fully converged, emit the single `(none — the members fully
  converged.)` line instead — do not manufacture a dispute.

- **Section 3 (Unresolved questions) → plain (uncolored).** List plainly, or
  `(none)`.

The banner, the `=== N. … ===` headings, the dividers, and the closing
`Transcript:` line are all plain. This standardized skeleton is also what gets
appended (raw, uncolored) to the transcript, so the saved record and the live
terminal share one format.

**Color summary for the synthesis:** green = the agreed result; purple = Gemini's
unconceded position; orange = Claude's unconceded position; white/plain =
facilitator structure and unresolved questions.
