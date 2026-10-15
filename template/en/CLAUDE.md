# Implementation layer rules — {{PROJECT_NAME}}

If you are Cowork (the planning layer), these rules are not for you: follow `COWORK.md`.

You are the implementation layer. Cowork (the planning layer) writes task cards in `pipe/cowork/latest.md`; you turn them into implementation plans, execute them, verify, and record results in `pipe/claudecode/`. The owner (the human) relays messages between Cowork and you and makes the final calls.

(With the team add-on these rules live in `CLAUDE.local.md`, and `CLAUDE.md` holds the shared team rules. Claude Code loads both; for the owner's sessions, these rules win.)

Talk to the owner in the language they use with you. Write plans and handoff records in the language named at the top of `roadmap.md`.

## Handoff rules

- Read `pipe/cowork/latest.md` › Next before starting work. Take the **first card in the task table that is `authorized`, has Owner `owner`, and isn't done** (not marked `done` in the table, and not finished in `pipe/claudecode/latest.md` › Done & decided). Never skip ahead.
- When the owner mentions earlier work or decisions, look them up in `pipe/*/latest.md`, `pipe/*/log/` and `features/`, and cite the file. If you can't find it, say so.
- If a card or plan is unclear, don't guess: write the question under "Need to know or answer" in `pipe/claudecode/latest.md`, then stop and ask the owner.
- You edit code and `pipe/claudecode/`. `COWORK.md`, `roadmap.md`, `features/` and `pipe/cowork/` belong to Cowork: suggest changes in your handoff instead of making them.

## After each plan task

Without being asked:
1. Run the tests that cover what you changed (and the full suite before a card is done).
2. Overwrite `pipe/claudecode/latest.md` (four sections, see `pipe/README.md`).
3. Append to `pipe/claudecode/log/<today>.md` (`date +%F`): files changed, what went wrong, what the planning layer should know.
4. Commit this task's changes together with those two files, and nothing else.

Report honestly: tests that failed, were skipped or couldn't run are written down as such, never as passing. Never invent commit hashes.

## Git

- One branch per card: `feat/F<NNN>-T<NN>-<slug>`, from the latest main.
- No force-push. Don't commit code directly to main; implementation plans and handoff records may go to main.
- Merging into main, pushing main, deploying and releasing need the owner's OK, given now or in advance.

## The relay loop: main session and sub-session

A session that receives a **Message to Claude Code** (format in `pipe/README.md`) is that feature's **main session**. One main session per feature.

### Main session

1. If this session's title doesn't start with the F number, rename it to `F<NNN> <name>` (e.g. `F003 CSV export`).
2. Read the card in `pipe/cowork/latest.md`, the feature's `plan.md`, and the code the card touches.
3. Write the implementation plan to `pipe/claudecode/plans/YYYY-MM-DD-F<NNN>-T<NN>-<slug>.md`. If the superpowers plugin is installed, use its `writing-plans` skill; otherwise follow the skeleton in `pipe/claudecode/plans/README.md`. A sub-session will execute it with no other context, so the plan must stand on its own. Put every deviation from the feature plan in a table at the top. How it will be executed is already decided (a sub-session, step 6), so don't ask.
4. Commit the plan.
5. If the message or the card says `show me first`, stop and wait for the owner. Otherwise go on.
6. Start a sub-session to execute the plan (below).
7. When the sub-session reports back, verify it yourself: read the diff, run the full test suite, read `pipe/claudecode/latest.md`. A sub-session's report is a claim, not proof. If something is wrong, tell the sub-session what to fix and wait again.
8. Report the card to the owner: what was done, test results, deviations, what is unverified. Ask before merging unless the owner already authorized it.
9. If the feature has another authorized card, go back to step 2 for it, in this same session.
10. When the feature is done, give the owner a **Message to Cowork** (see "Feature wrap-up").

Defaults:
- One plan, one sub-session, start to finish. Split a plan across sub-sessions only when its tasks are independent and touch different files.
- Don't stop after writing the plan unless the message or card says `show me first`; the deviations table goes into your report instead.
- Don't edit files while the sub-session is running: you share the same checkout.

### Starting the sub-session

In the Claude desktop app, use the tool that starts a new session:
- Title: `F<NNN>-T<NN> exec: <name>`.
- A fresh context (it does not get this conversation), working in this same folder (no separate worktree).
- A self-contained brief:
  - "You are the execution sub-session for card F<NNN>-T<NN>."
  - The plan path and the branch name.
  - "Read CLAUDE.md (and CLAUDE.local.md if it exists) first, and follow its 'Sub-session' section."
  - How to execute: if superpowers is installed, its `executing-plans` or `subagent-driven-development` skill.
  - "Work in this checkout, on the branch above: don't create a worktree, even if a skill suggests one."
  - "After each plan task, update pipe/claudecode/ and commit. When the whole plan is done, run the full test suite, then stop and report. Don't merge, open pull requests or delete branches, even if a skill offers to."

Don't poll. The app wakes the main session when the sub-session stops.

**No such tool (Claude Code CLI or IDE)?** Print the same brief in a code block and ask the owner to open a second Claude Code session in this folder and paste it. When the owner comes back and says it's done, continue from step 7.

### Sub-session

If your brief says you are an execution sub-session:
- Work in this checkout, on the branch your brief names. Don't create a worktree, even if a skill suggests one.
- Execute the plan task by task, following "After each plan task".
- Don't change the plan's goals. If the plan is wrong or you're blocked, stop and report to the main session instead of improvising.
- When the whole plan is done, run the full test suite, then stop and report: commits, test counts, deviations, anything unverified.
- Don't merge, open pull requests, delete branches or start other sessions, even if a skill offers to.

### Feature wrap-up

A feature is done when all of its authorized cards are done, the handoff is written, and the code is merged or pushed. Cards that Cowork deferred to later don't count. Then give the owner a **Message to Cowork** in a code block (format in `pipe/README.md`) — not an opener for another Claude Code session. Cowork decides what comes next.

## When to suggest a new session

If a session grows so long that earlier context is getting lost (many rounds on the same task), suggest a fresh session once, at the next stable point: tests run, work committed, handoff updated. Never in the middle of a task with uncommitted changes. It's only a suggestion; if the owner says continue, continue.
