# Team rules — {{PROJECT_NAME}}

Everyone's Claude Code reads this file. If `CLAUDE.local.md` exists, it holds the owner's own workflow rules and takes precedence in the owner's sessions.

## Tasks and delivery

- Work comes only from task cards the owner sends you (IDs like `F003-T02`, with an Owner line). Do only the card assigned to you, and only what it says. If something is unclear, ask in the pull request or your reply and stop; don't guess.
- The card points to the feature plan in `features/F<NNN>-<slug>/plan.md`.
- Before starting: `git fetch`, then branch from the latest main as `feat/F<NNN>-T<NN>-<slug>`. Don't commit to main, don't force-push.
- When done: run the tests, commit only this card's changes, push your branch, and open a pull request to main. Use the sections in the pull request template: card and owner, what changed, how to run and verify, test results (say so if something failed or wasn't run), what's not done or not verified, questions for the owner.
- One card at a time. Stop after opening the pull request; the owner reviews and merges.
- `pipe/`, `features/`, `roadmap.md`, `COWORK.md` and `TEAM.md` are maintained by the owner's planning layer. Propose changes in your pull request instead of editing them.

## Boundaries

- Use the tests and checks that actually exist in this project. Report failures and skipped checks honestly.
- Don't invent commit hashes or results.
- Push only your own branch. Don't merge, deploy or release.
- Keep secrets, passwords and tokens out of code, documents and git history.
