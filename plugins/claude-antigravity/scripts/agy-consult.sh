#!/bin/sh
# agy-consult.sh — consultation wrapper for the claude-antigravity plugin.
#
# Asks Google Gemini (through the Antigravity CLI binary "agy", in headless
# print mode) for a second opinion, fact-check, or code review, then displays
# the answer in Gemini purple so the user sees it while Claude can still read
# the plain text for cross-checking.
#
# Usage:
#   agy-consult.sh [--add-dir DIR] [--out FILE] [--label LABEL] PROMPT...
#
#   --add-dir DIR   Add DIR to agy's workspace (agy's default workspace is
#                   ~/.gemini/antigravity-cli/scratch, NOT the cwd). Use for a
#                   larger scoped directory; for small diffs prefer embedding
#                   the code inline in PROMPT (zero-trust, nothing extra shared).
#   --out FILE      Also write the RAW (uncolored) Gemini response to FILE.
#   --label LABEL   Short label shown in the header line (e.g. "fact-check").
#   PROMPT...       The task for Gemini. Everything after the recognized flags
#                   is joined with spaces into the prompt.
#
# Environment:
#   AGY_PRINT_TIMEOUT  agy --print-timeout value (Go duration). Default 300s.
#   NO_COLOR           If set+non-empty, output is emitted without color.
#
# The zero-trust security prompt is the SINGLE SOURCE OF TRUTH in
# references/security-prompt.md; we read it at runtime and prepend it.

set -u

# Resolve this script's directory portably (handles symlinks-by-dir and spaces).
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)

SECURITY_PROMPT_FILE="$SCRIPT_DIR/../references/security-prompt.md"
COLORIZE="$SCRIPT_DIR/colorize.sh"

# --- Parse arguments with a POSIX while/case loop (no bashisms, no arrays) ---
ADD_DIR=
OUT_FILE=
LABEL=
PROMPT=

while [ $# -gt 0 ]; do
	case "$1" in
		--add-dir)
			if [ $# -lt 2 ]; then
				printf '%s\n' "agy-consult.sh: --add-dir requires a directory argument" >&2
				exit 2
			fi
			ADD_DIR=$2
			shift 2
			;;
		--out)
			if [ $# -lt 2 ]; then
				printf '%s\n' "agy-consult.sh: --out requires a file argument" >&2
				exit 2
			fi
			OUT_FILE=$2
			shift 2
			;;
		--label)
			if [ $# -lt 2 ]; then
				printf '%s\n' "agy-consult.sh: --label requires a value" >&2
				exit 2
			fi
			LABEL=$2
			shift 2
			;;
		--)
			# Everything after -- is prompt text.
			shift
			break
			;;
		-*)
			printf '%s\n' "agy-consult.sh: unknown option: $1" >&2
			exit 2
			;;
		*)
			# First non-flag token starts the prompt; stop flag parsing.
			break
			;;
	esac
done

# Remaining positional params form the prompt; join with single spaces.
for word in "$@"; do
	if [ -z "$PROMPT" ]; then
		PROMPT=$word
	else
		PROMPT="$PROMPT $word"
	fi
done

if [ -z "$PROMPT" ]; then
	printf '%s\n' "agy-consult.sh: no PROMPT given" >&2
	printf '%s\n' "usage: agy-consult.sh [--add-dir DIR] [--out FILE] [--label LABEL] PROMPT..." >&2
	exit 2
fi

# --- Load the zero-trust security prompt (single source of truth) ---
if [ ! -f "$SECURITY_PROMPT_FILE" ]; then
	printf '%s\n' "agy-consult.sh: missing security prompt: $SECURITY_PROMPT_FILE" >&2
	exit 1
fi
SECURITY_PROMPT=$(cat "$SECURITY_PROMPT_FILE")

# Compose FULL_PROMPT = security text + blank line + user prompt.
FULL_PROMPT=$(printf '%s\n\n%s' "$SECURITY_PROMPT" "$PROMPT")

# --- Build the agy argument list safely with positional params (no arrays) ---
# agy contract (v1.0.3, verified):
#   * --dangerously-skip-permissions auto-approves tool requests so a headless
#     run never blocks on a permission prompt.
#   * --print-timeout is a Go duration. Default 300s (5 minutes): consultations
#     can include code review / fact-checking that needs the model to reason and
#     use the internet, so a short timeout would cut off legitimate answers;
#     5 minutes matches agy's own documented default and is overridable via
#     AGY_PRINT_TIMEOUT for slower or faster needs.
#   * -p is a STRING flag that consumes the NEXT token, so it MUST be last and
#     the prompt MUST come immediately after it. Any optional flags (--add-dir)
#     go BEFORE -p.
set -- agy --dangerously-skip-permissions
if [ -n "$ADD_DIR" ]; then
	set -- "$@" --add-dir "$ADD_DIR"
fi
set -- "$@" --print-timeout "${AGY_PRINT_TIMEOUT:-300s}" -p "$FULL_PROMPT"

# --- Run agy, capturing combined stdout+stderr and the exit status ---
RESPONSE=$("$@" 2>&1)
STATUS=$?

esc=$(printf '\033')
if [ -n "${NO_COLOR:-}" ]; then
	RULE="------------------------------------------------------------"
else
	# Dim rule in the Gemini purple so the header reads as a Gemini block.
	RULE="${esc}[38;2;158;159;230m------------------------------------------------------------${esc}[0m"
fi

HEADER="Gemini · via agy"
if [ -n "$LABEL" ]; then
	HEADER="$HEADER · $LABEL"
fi

if [ "$STATUS" -ne 0 ]; then
	# Error path: still print readably so the user/Claude can see what happened.
	printf '%s\n' "$RULE"
	printf '%s\n' "$HEADER (FAILED, exit $STATUS)" | "$COLORIZE" gemini
	printf '\n'
	printf '%s\n' "$RESPONSE" | "$COLORIZE" gemini
	printf '\n'
	printf '%s\n' "$RULE"
	printf '%s\n' "agy-consult.sh: agy exited with status $STATUS" >&2
	exit "$STATUS"
fi

# Optionally persist the RAW (uncolored) response.
if [ -n "$OUT_FILE" ]; then
	printf '%s\n' "$RESPONSE" > "$OUT_FILE" || {
		printf '%s\n' "agy-consult.sh: failed to write --out file: $OUT_FILE" >&2
		exit 1
	}
fi

# Display: purple header rule + Gemini answer through colorize.sh (role gemini).
printf '%s\n' "$RULE"
printf '%s\n' "$HEADER" | "$COLORIZE" gemini
printf '\n'
printf '%s\n' "$RESPONSE" | "$COLORIZE" gemini
printf '\n'
printf '%s\n' "$RULE"
