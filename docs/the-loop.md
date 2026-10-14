# One feature, start to finish

This walkthrough follows one feature through the loop in a made-up project, **Recipe Box**, a small web app for saving recipes. The messages below are examples of what you would actually paste.

## 0. Set up

```bash
claude-relay-loop/init.sh ~/code/recipe-box --name "Recipe Box"
```

## 1. Onboarding (Cowork)

Open Cowork on `~/code/recipe-box` and say:

> Read COWORK.md and onboard me.

Cowork reads the folder, then asks a few questions at a time: what the app is for, who uses it, what the first useful result is. From your answers it writes `roadmap.md` and proposes a first feature. Once you confirm it, Cowork writes `features/F001-ingredient-search/plan.md` and the first task card in `pipe/cowork/latest.md`:

```markdown
| ID | Task | Owner | Status |
|---|---|---|---|
| F001-T01 | Search recipes by ingredient | owner | authorized |

### F001-T01 — Search recipes by ingredient
- What: a search box on the recipe list that filters by one or more ingredients.
- Refs: features/F001-ingredient-search/plan.md §3, §5
- Scope and limits: in: ingredient names, case-insensitive. Out: fuzzy matching, units.
- Acceptance: typing "egg, flour" shows only recipes that contain both; clearing the box shows all recipes.
- Prerequisites / open questions: none
- Plan review: skip
- Status: authorized (owner, 2026-10-14)
```

Then it asks you to commit the planning files (Claude Code may start from a fresh checkout), and gives you:

```text
F001 Ingredient search — main session kickoff
Card: F001-T01 (pipe/cowork/latest.md › Next)
Plan review: skip — write the plan, then start the sub-session right away
Read first: features/F001-ingredient-search/plan.md
Notes: keep the search client-side; the recipe list is small.
```

## 2. Main session (Claude Code)

Open the Code tab in the Claude desktop app on the same folder, start a new session, and paste the message. The main session:

1. renames itself **F001 Ingredient search**;
2. reads the card, the feature plan and the code;
3. writes `pipe/claudecode/plans/2026-10-14-F001-T01-ingredient-search.md` and commits it;
4. starts a sub-session titled **F001-T01 exec: ingredient search** with a brief like this:

```text
You are the execution sub-session for card F001-T01.
Plan: pipe/claudecode/plans/2026-10-14-F001-T01-ingredient-search.md
Branch: feat/F001-T01-ingredient-search (create it from main)
Read CLAUDE.md (and CLAUDE.local.md if it exists) first and follow its "Sub-session" section.
Work in this checkout, on that branch: don't create a worktree.
Execute the plan task by task. After each task, update pipe/claudecode/latest.md and today's log, and commit them with the task's changes.
When the whole plan is done, run the full test suite, then stop and report: commits, test counts, deviations, anything unverified.
Don't merge, open pull requests or delete branches.
```

Then it waits. It doesn't poll: the app wakes it when the sub-session stops.

## 3. Sub-session (Claude Code)

The sub-session works through the plan one task at a time: failing test, implementation, passing test, handoff update, commit. You can open it from the sidebar whenever you like, to watch or to talk to it. When it's done, it reports to the main session.

## 4. Verify and report (main session)

The main session doesn't take the report on trust. It reads the diff, runs the full test suite itself, and reads `pipe/claudecode/latest.md`. If something is off, it tells the sub-session what to fix and waits again. Then it reports to you: what was done, test results, deviations, what's unverified. It asks before merging.

If the feature had a second authorized card, the main session would now write that card's plan and start another sub-session, in the same session.

## 5. Wrap-up: Message to Cowork

With every authorized card done and merged, the main session gives you:

```text
F001 Ingredient search is done.
Cards: F001-T01. Merged into main: yes (4f2c9e1).
Tests: full suite passing (48 tests).
Read: COWORK.md if you haven't this session, then pipe/claudecode/latest.md › Done & decided (deviations), Need to know or answer.
Unverified: not tried with more than 500 recipes.
Needs your decision: accept the deviation (search also matches recipe titles)?
Please update the plan status, task table and roadmap, then give me the Message to Claude Code for the next feature.
```

## 6. Back in Cowork

Paste it into Cowork. Cowork reads the handoff, asks you about the deviation, marks F001 done in the plan, the task table and the roadmap, logs the session, and plans F002 with you. It ends with the next Message to Claude Code, and a new Claude Code session takes it from there.

## Without the desktop app

The Claude Code CLI and IDE extensions can't start a sub-session. The main session prints the brief from step 2 in a code block instead. Open a second session in the same folder, paste the brief, and when it finishes, go back to the main session and say it's done. The main session then verifies as in step 4.

## When something goes wrong

- **The sub-session is blocked, or the plan is wrong.** It stops and reports to the main session instead of improvising. The main session fixes the plan or asks you.
- **A planning question comes up** (the card is unclear, the scope needs to change). Claude Code writes it under "Need to know or answer" and stops. Take it to Cowork, let Cowork update the card, and continue.
- **A session gets too long.** Either side suggests a fresh session at a stable point. Nothing is lost, because everything is in files.
