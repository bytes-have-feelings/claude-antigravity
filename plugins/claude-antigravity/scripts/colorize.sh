#!/bin/sh
# colorize.sh — stdin->stdout color filter for the claude-antigravity plugin.
#
# Usage: colorize.sh <role>
#   role = gemini  -> 24-bit truecolor purple  #9e9fe6 (ANSI 38;2;158;159;230)
#   role = claude  -> 24-bit truecolor orange  #e28558 (ANSI 38;2;226;133;88)
#   role = council -> 24-bit truecolor green   #5cb87a (ANSI 38;2;92;184;122)
#                     (the council's CONVERGED result — what both members agree on)
#   role = facilitator -> no color (default/white terminal text)
#   anything else  -> no color (treated like facilitator)
#
# Reads ALL of stdin, writes it wrapped in the role color to stdout, and always
# closes a colored run with ESC[0m. Honors the NO_COLOR convention: if NO_COLOR
# is set and non-empty, output is passed through unchanged.
#
# Truecolor rendering depends on the terminal (and Claude Code) passing ANSI
# through. 24-bit support is an ASSUMPTION, not a guarantee; uncolored fallback
# degrades gracefully.

role=$1

# Determine the color sequence (empty means "no color").
color=
case "$role" in
	gemini)
		color="38;2;158;159;230"
		;;
	claude)
		color="38;2;226;133;88"
		;;
	council)
		color="38;2;92;184;122"
		;;
	*)
		# facilitator or unknown -> no color
		color=
		;;
esac

# No color when NO_COLOR is set+non-empty, or when the role has no color:
# pass stdin straight through.
if [ -n "${NO_COLOR:-}" ] || [ -z "$color" ]; then
	cat
	exit 0
fi

# Obtain the ESC byte portably (octal %b is ambiguous in some shells).
esc=$(printf '\033')

# Open color, stream all of stdin verbatim, then always reset.
printf '%s' "${esc}[${color}m"
cat
printf '%s' "${esc}[0m"
