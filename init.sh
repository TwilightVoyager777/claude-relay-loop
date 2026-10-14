#!/usr/bin/env bash
# claude-relay-loop: set up the Cowork <-> Claude Code relay loop in a project folder.
# https://github.com/TwilightVoyager777/claude-relay-loop
#
# Works with bash 3.2+ (the macOS default). Needs git and perl.
# The --auto-push hook needs jq when it runs.
set -euo pipefail

VERSION="0.1.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TEMPLATE_DIR="$SCRIPT_DIR/template"
TEAM_DIR="$SCRIPT_DIR/addons/team"
AUTO_PUSH_SCRIPT="$SCRIPT_DIR/addons/auto-push/auto-push.sh"

usage() {
  cat <<'EOF'
Usage: init.sh <target-dir> [options]

Copy the claude-relay-loop scaffold into <target-dir> (created if missing).
Existing files are never overwritten; they are listed as skipped.

Options:
  --name <name>       Project name used in the files (default: the folder name)
  --team              Add the team add-on: shared CLAUDE.md for teammates,
                      your own loop rules in CLAUDE.local.md (git-ignored)
  --no-attribution    Write .claude/settings.json that turns off AI attribution
                      in commits and pull requests
  --auto-push         Add a hook that pushes the current branch after every
                      commit Claude Code makes (the hook needs jq)
  --dry-run           Show what would be created or skipped; write nothing
  -h, --help          Show this help
  --version           Show the version
EOF
}

die() {
  printf 'init.sh: error: %s\n' "$*" >&2
  exit 2
}

# Print an absolute, symlink-resolved path for $1, which may not exist yet.
abs_path() {
  local p="$1" rest=""
  case "$p" in
    /*) ;;
    *) p="$PWD/$p" ;;
  esac
  while [ ! -d "$p" ]; do
    rest="/$(basename "$p")$rest"
    p="$(dirname "$p")"
  done
  printf '%s%s\n' "$(cd "$p" && pwd -P)" "$rest"
}

TARGET=""
NAME=""
TEAM=0
NO_ATTRIBUTION=0
AUTO_PUSH=0
DRY_RUN=0

while [ $# -gt 0 ]; do
  case "$1" in
    --name)
      [ $# -ge 2 ] || die "--name needs a value"
      NAME="$2"
      shift 2
      ;;
    --name=*) NAME="${1#--name=}"; shift ;;
    --team) TEAM=1; shift ;;
    --no-attribution) NO_ATTRIBUTION=1; shift ;;
    --auto-push) AUTO_PUSH=1; shift ;;
    --dry-run) DRY_RUN=1; shift ;;
    -h | --help) usage; exit 0 ;;
    --version) echo "$VERSION"; exit 0 ;;
    -*) die "unknown option: $1 (see --help)" ;;
    *)
      [ -z "$TARGET" ] || die "only one target directory is allowed"
      TARGET="$1"
      shift
      ;;
  esac
done

if [ -z "$TARGET" ]; then
  usage >&2
  exit 2
fi
[ -d "$TEMPLATE_DIR" ] || die "template/ not found next to init.sh ($SCRIPT_DIR)"
if [ "$TEAM" = 1 ] && [ ! -d "$TEAM_DIR" ]; then die "addons/team/ not found next to init.sh"; fi
if [ "$AUTO_PUSH" = 1 ] && [ ! -f "$AUTO_PUSH_SCRIPT" ]; then die "addons/auto-push/auto-push.sh not found next to init.sh"; fi
command -v perl >/dev/null 2>&1 || die "perl is required"
if [ -e "$TARGET" ] && [ ! -d "$TARGET" ]; then die "$TARGET exists and is not a directory"; fi

TARGET_ABS="$(abs_path "$TARGET")"
case "$TARGET_ABS/" in
  "$SCRIPT_DIR/"*) die "the target is inside the scaffold itself ($SCRIPT_DIR); pick your project's folder" ;;
esac
[ -n "$NAME" ] || NAME="$(basename "$TARGET_ABS")"
TODAY="$(date +%F)"

PLAN="$(mktemp "${TMPDIR:-/tmp}/relay-loop.XXXXXX")"
trap 'rm -f "$PLAN"' EXIT

# Queue every file under a source root as "<source>\t<destination>".
add_tree() {
  local root="$1" rel dest
  while IFS= read -r rel; do
    rel="${rel#./}"
    dest="$rel"
    if [ "$TEAM" = 1 ] && [ "$root" = "$TEMPLATE_DIR" ] && [ "$rel" = "CLAUDE.md" ]; then
      dest="CLAUDE.local.md"
    fi
    printf '%s\t%s\n' "$root/$rel" "$dest" >>"$PLAN"
  done < <(cd "$root" && find . -type f ! -name .DS_Store | LC_ALL=C sort)
}

add_tree "$TEMPLATE_DIR"
if [ "$TEAM" = 1 ]; then add_tree "$TEAM_DIR"; fi
if [ "$AUTO_PUSH" = 1 ]; then
  printf '%s\t%s\n' "$AUTO_PUSH_SCRIPT" ".claude/hooks/auto-push.sh" >>"$PLAN"
fi

CREATED=0
SKIPPED=0
SKIPPED_LIST=""
LOCAL_CREATED=0
TEAM_CLAUDE_SKIPPED=0
RULES_SKIPPED=0
RULES_DEST="CLAUDE.md"
if [ "$TEAM" = 1 ]; then RULES_DEST="CLAUDE.local.md"; fi

if [ "$DRY_RUN" = 1 ]; then echo "Dry run: nothing will be written."; fi
echo "Setting up claude-relay-loop in $TARGET_ABS"
if [ "$DRY_RUN" = 0 ]; then mkdir -p "$TARGET_ABS"; fi

while IFS=$'\t' read -r src dest; do
  if [ -e "$TARGET_ABS/$dest" ]; then
    echo "  skip    $dest (already exists)"
    SKIPPED=$((SKIPPED + 1))
    SKIPPED_LIST="$SKIPPED_LIST    $dest  <-  $src
"
    if [ "$TEAM" = 1 ] && [ "$dest" = "CLAUDE.md" ]; then TEAM_CLAUDE_SKIPPED=1; fi
    if [ "$dest" = "$RULES_DEST" ]; then RULES_SKIPPED=1; fi
    continue
  fi
  echo "  create  $dest"
  CREATED=$((CREATED + 1))
  if [ "$dest" = "CLAUDE.local.md" ]; then LOCAL_CREATED=1; fi
  if [ "$DRY_RUN" = 1 ]; then continue; fi
  mkdir -p "$(dirname "$TARGET_ABS/$dest")"
  cp "$src" "$TARGET_ABS/$dest"
  # shellcheck disable=SC2016 # $ENV{...} is perl, not shell
  RL_NAME="$NAME" RL_DATE="$TODAY" perl -pi -e 's/\{\{PROJECT_NAME\}\}/$ENV{RL_NAME}/g; s/\{\{DATE\}\}/$ENV{RL_DATE}/g' "$TARGET_ABS/$dest"
  case "$dest" in
    *.sh) chmod +x "$TARGET_ABS/$dest" ;;
  esac
done <"$PLAN"

# Create a settings file, or print its content when the file already exists.
write_or_print() {
  local dest="$1" content="$2"
  if [ -e "$TARGET_ABS/$dest" ]; then
    echo "  skip    $dest (already exists). Merge this in yourself:"
    printf '%s\n' "$content" | sed 's/^/            /'
    SKIPPED=$((SKIPPED + 1))
    return 0
  fi
  echo "  create  $dest"
  CREATED=$((CREATED + 1))
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  mkdir -p "$(dirname "$TARGET_ABS/$dest")"
  printf '%s\n' "$content" >"$TARGET_ABS/$dest"
}

# Append a line to the target's .gitignore unless it is already there.
ensure_gitignore_line() {
  local line="$1" gi="$TARGET_ABS/.gitignore"
  if [ -f "$gi" ] && grep -qxF -- "$line" "$gi"; then return 0; fi
  echo "  append  .gitignore: $line"
  if [ "$DRY_RUN" = 1 ]; then return 0; fi
  if [ -s "$gi" ] && [ -n "$(tail -c1 "$gi")" ]; then printf '\n' >>"$gi"; fi
  printf '%s\n' "$line" >>"$gi"
}

ATTRIBUTION_JSON='{
  "attribution": {
    "commit": "",
    "pr": ""
  }
}'

# shellcheck disable=SC2016 # $CLAUDE_PROJECT_DIR is expanded by Claude Code, not here
AUTO_PUSH_JSON='{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/auto-push.sh",
            "timeout": 60
          }
        ]
      }
    ]
  }
}'

if [ "$NO_ATTRIBUTION" = 1 ]; then write_or_print ".claude/settings.json" "$ATTRIBUTION_JSON"; fi
if [ "$AUTO_PUSH" = 1 ]; then
  write_or_print ".claude/settings.local.json" "$AUTO_PUSH_JSON"
  ensure_gitignore_line ".claude/settings.local.json"
  command -v jq >/dev/null 2>&1 || echo "  note    jq not found: the auto-push hook needs it when it runs"
fi
if [ "$TEAM" = 1 ]; then ensure_gitignore_line "CLAUDE.local.md"; fi

if ! command -v git >/dev/null 2>&1; then
  echo "  git     git not found: skipped git init"
elif git -C "$TARGET_ABS" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "  git     already a git repository: left as is, nothing committed"
elif [ "$DRY_RUN" = 1 ]; then
  echo "  git     would run git init"
else
  git init -q -b main "$TARGET_ABS" 2>/dev/null || git init -q "$TARGET_ABS"
  echo "  git     initialized, nothing committed"
fi

echo
if [ "$DRY_RUN" = 1 ]; then
  echo "Dry run: would create $CREATED, skip $SKIPPED."
else
  echo "Created $CREATED, skipped $SKIPPED."
fi
if [ -n "$SKIPPED_LIST" ]; then
  echo "Existing files were left untouched. To merge by hand, compare them with the scaffold's copy:"
  printf '%s' "$SKIPPED_LIST"
fi
if [ "$RULES_SKIPPED" = 1 ] && ! grep -qsF -- "## The relay loop: main session and sub-session" "$TARGET_ABS/CLAUDE.md" "$TARGET_ABS/CLAUDE.local.md"; then
  echo "Note: your $RULES_DEST doesn't have the relay-loop rules, so Claude Code won't follow the loop yet."
  echo "  Copy in everything below the title line of $TEMPLATE_DIR/CLAUDE.md."
fi
if [ "$TEAM_CLAUDE_SKIPPED" = 1 ] && [ "$LOCAL_CREATED" = 1 ]; then
  echo "Team setup: CLAUDE.md already exists, so the shared team rules were not written."
  echo "  If it holds the relay-loop rules from a solo setup, switch with:"
  printf '    mv %q %q && %q %q --team --name %q\n' "$TARGET_ABS/CLAUDE.md" "$TARGET_ABS/CLAUDE.local.md" "$SCRIPT_DIR/init.sh" "$TARGET_ABS" "$NAME"
fi
if [ "$DRY_RUN" = 0 ]; then
  echo
  echo "Next steps:"
  echo "  1. Open Cowork on this folder: $TARGET_ABS"
  echo "  2. Say: Read COWORK.md and onboard me."
  echo "  3. Cowork will give you a \"Message to Claude Code\". Paste it into a new Claude Code session in the same folder."
fi
