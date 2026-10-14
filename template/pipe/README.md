# pipe/ — the handoff area

Cowork (planning) and Claude Code (implementation) never talk to each other directly. They hand work over through the files here, and the owner relays one short message each way per feature.

| Path | Written by | Holds |
|---|---|---|
| `cowork/latest.md` | Cowork | Current state, task table, task cards (overwritten) |
| `cowork/log/YYYY-MM-DD.md` | Cowork | History (append-only) |
| `claudecode/latest.md` | Claude Code | Current implementation state (overwritten) |
| `claudecode/log/YYYY-MM-DD.md` | Claude Code | History (append-only) |
| `claudecode/plans/` | Claude Code | Implementation plans, one per card |

Each side writes only its own folder and may read the other's. Neither rewrites the other's conclusions.

## The loop

```
Cowork ──Message to Claude Code──▶ owner ──▶ Claude Code main session "F003 …"
                                                │ writes the plan, starts sub-session "F003-T01 exec: …"
                                                │ verifies, reports each card
Cowork ◀──Message to Cowork─────── owner ◀──────┘ when the feature is done
```

## latest.md: four sections

Both `latest.md` files use the same four sections, in this order:

1. **Now**: what is being worked on.
2. **Done & decided**: finished work and decisions, with dates and commits.
3. **Next**: on Cowork's side, the task table and then the task cards; on Claude Code's side, what it will do next.
4. **Need to know or answer**: questions and facts the other side needs.

## Message to Claude Code

Cowork writes this when a feature is ready to build. The owner pastes it into a **new** Claude Code session.

```text
F003 CSV export — main session kickoff
Card: F003-T01 (pipe/cowork/latest.md › Next)
Plan review: skip — write the plan, then start the sub-session right away
Read first: features/F003-csv-export/plan.md
Notes: the export must keep the column order in plan.md §3.
```

- The first line starts with the F number, so the session title does too.
- `Plan review` is `skip` or `show me first`.
- `Notes` is optional: anything the card doesn't say.

## Message to Cowork

The Claude Code main session writes this when the feature is done. The owner pastes it into Cowork.

```text
F003 CSV export is done.
Cards: F003-T01, F003-T02. Merged into main: yes (a1b2c3d).
Tests: full suite passing (212 tests).
Read: COWORK.md if you haven't this session, then pipe/claudecode/latest.md › Done & decided (deviations), Need to know or answer.
Unverified: exports of more than 100,000 rows were not tried.
Needs your decision: accept deviation 2 (dates exported as ISO 8601)?
Please update the plan status, task table and roadmap, then give me the Message to Claude Code for the next feature.
```

## Logs

One file per day, named with `date +%F`. Append; never rewrite earlier entries. Each entry: time, F number or card, what changed or was decided, why, and what the other side should know.
