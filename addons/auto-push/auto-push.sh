#!/usr/bin/env bash
# PostToolUse hook for Claude Code's Bash tool: after a command that ran
# `git commit`, push the current branch to origin.
# Installed by claude-relay-loop's init.sh --auto-push. Needs jq.
cmd="$(jq -r '.tool_input.command // ""')"
case "$cmd" in
  *"git commit"*) ;;
  *) exit 0 ;;
esac
cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0
if out="$(git push -u origin HEAD 2>&1)"; then
  msg="auto push: $(printf '%s' "$out" | tail -n 1)"
else
  msg="auto push failed: $(printf '%s' "$out" | tail -n 1)"
fi
# shellcheck disable=SC2016 # $m is a jq variable
jq -n --arg m "$msg" '{systemMessage: $m}'
