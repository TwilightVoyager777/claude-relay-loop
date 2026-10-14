# Implementation plans

One plan per task card, written by the Claude Code main session and executed by a sub-session.

File name: `YYYY-MM-DD-F<NNN>-T<NN>-<slug>.md`, e.g. `2026-10-14-F003-T01-csv-export.md`.

If the superpowers plugin is installed, write plans with its `writing-plans` skill. Otherwise use the skeleton below. The sub-session gets nothing but this plan and the rules in `CLAUDE.md`, so write it for someone with no context.

~~~markdown
# F<NNN>-T<NN> <title> — implementation plan

Card: F<NNN>-T<NN> (pipe/cowork/latest.md › Next) · Feature plan: features/F<NNN>-<slug>/plan.md
Branch: feat/F<NNN>-T<NN>-<slug> (from main at <commit>)
Goal: <one sentence>

## Deviations from the feature plan
| # | Feature plan says | This plan does | Why |
|---|---|---|---|

## Tasks

### Task 1: <name>
Files: <exact paths to create or modify>
Steps:
1. Write the failing test: <code, or an exact description>
2. Run <command>; expect it to fail with <message>.
3. Implement: <code, or an exact description>
4. Run <command>; expect <N> passing.
5. Commit `<message>`, then update pipe/claudecode/latest.md and today's log.

### Task N: Full check and handoff
1. Run <full test command>; expect <counts>.
2. Write pipe/claudecode/latest.md (deviations, unverified items, questions) and today's log.
3. Stop and report to the main session.
~~~
