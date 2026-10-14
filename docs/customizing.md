# Customizing

## AI attribution in commits and pull requests (`--no-attribution`)

By default Claude Code adds a co-author line to commits and a note to pull request descriptions. `--no-attribution` writes `.claude/settings.json`:

```json
{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}
```

If the file already exists, `init.sh` leaves it alone and prints this snippet for you to merge. The file isn't git-ignored: once you commit it, it applies to everyone who works in the repository with Claude Code.

## Push after every commit (`--auto-push`)

Adds `.claude/hooks/auto-push.sh` and wires it up as a `PostToolUse` hook in `.claude/settings.local.json`, which is git-ignored and only affects you. After any Bash command Claude Code runs that contains `git commit`, the hook runs `git push -u origin HEAD` and shows the last line of the result.

- The hook needs `jq` when it runs.
- It pushes whatever branch is checked out to `origin`. That includes `main` when the main session commits a plan there. If you don't want every commit on the remote right away, don't use it.
- To turn it off, delete the `hooks` entry from `.claude/settings.local.json`.

## The loop's defaults

The defaults are in `CLAUDE.md` (in `CLAUDE.local.md` with `--team`), under "Defaults":

- **Plan review.** The main session starts the sub-session right after writing the plan. To review a plan first, have Cowork write `Plan review: show me first` on that card, or change the default for every card.
- **One sub-session per plan.** Split a plan only when its tasks are independent and touch different files.

## Project files in another language

The rule files are in English, and both layers already reply in your language. To have Cowork and Claude Code write the project's files (roadmap, plans, handoff records) in another language, change the "Files are written in" line at the top of `roadmap.md`, or ask Cowork to do it during onboarding.

## Adding the team add-on later

Running `init.sh --team` on a project that already has the solo setup skips `CLAUDE.md`, because it exists, and prints the command to switch, with your paths and project name filled in. It looks like this:

```bash
mv path/to/my-project/CLAUDE.md path/to/my-project/CLAUDE.local.md && claude-relay-loop/init.sh path/to/my-project --team --name "My Project"
```

`CLAUDE.local.md` then holds your own loop rules (git-ignored), and the new `CLAUDE.md` holds the shared rules for teammates.

## Updating the rules later

`init.sh` doesn't update projects that already use the loop. To pick up newer rules, compare your files with the latest `template/` and merge by hand.
