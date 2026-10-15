# Working with teammates — {{PROJECT_NAME}}

Cowork reads this file at the start of every session (COWORK.md §2). Teammates follow `CLAUDE.md`; the owner's own Claude Code follows `CLAUDE.local.md`.

## Members

| Name | Area | Tools |
|---|---|---|

Cowork fills this in with the owner.

## How teammates get work

1. Cowork writes the card in `pipe/cowork/latest.md` › Next as usual, with the teammate in the Owner column.
2. Cowork also writes the card as a file the owner can send: `features/F<NNN>-<slug>/F<NNN>-T<NN>-card.md`, from `features/_template/task-card.md`.
3. The owner commits and pushes the planning files, so the teammate can read the feature plan, then sends the card file to the teammate. Cowork never contacts teammates directly.
4. The teammate delivers a branch and a pull request. The pull request description is their implementation record; teammates don't use `pipe/`.

## Reading results

- The owner pastes the pull request (or its link and description) into Cowork. Cowork updates the task table, the feature plan and the roadmap, and notes in `pipe/cowork/latest.md` what the owner still has to decide.
- Before writing a new card, check merged pull requests so work isn't assigned twice.
- Merging, releasing and changing plans are the owner's calls.

## Agreements between teammates

When two people's work overlaps (shared data, an interface between modules), write the agreement as its own feature first, and merge it before both sides build on it.
