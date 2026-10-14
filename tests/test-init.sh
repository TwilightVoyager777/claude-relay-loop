#!/usr/bin/env bash
# Black-box tests for init.sh. Run: tests/test-init.sh [name-filter]
# On macOS, run with TEST_BASH=/bin/bash to exercise the system bash 3.2.
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INIT="$ROOT/init.sh"
TEST_BASH="${TEST_BASH:-bash}"
TODAY="$(date +%F)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/relay-loop-test.XXXXXX")"
WORK="$(cd "$WORK" && pwd -P)"
trap 'rm -rf "$WORK"' EXIT

# Keep the user's git config (signing, hooks, default branch) out of the tests.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

CORE_FILES="COWORK.md CLAUDE.md roadmap.md features/README.md features/_template/plan.md pipe/README.md pipe/cowork/latest.md pipe/cowork/log/.gitkeep pipe/claudecode/latest.md pipe/claudecode/log/.gitkeep pipe/claudecode/plans/README.md"
TEAM_FILES="CLAUDE.local.md TEAM.md features/_template/task-card.md .github/pull_request_template.md"

PASS=0
FAIL=0
STATUS=0
OUT="$WORK/out.txt"

ok() { PASS=$((PASS + 1)); }
fail() { printf '    FAIL: %s\n' "$*"; FAIL=$((FAIL + 1)); }
rel() { printf '%s' "${1#"$WORK"/}"; }
assert_file() { if [ -f "$1" ]; then ok; else fail "missing file: $(rel "$1")"; fi; }
assert_absent() { if [ ! -e "$1" ]; then ok; else fail "should not exist: $(rel "$1")"; fi; }
assert_contains() { if grep -qF -- "$2" "$1" 2>/dev/null; then ok; else fail "$(rel "$1") should contain: $2"; fi; }
assert_lacks() { if grep -qF -- "$2" "$1" 2>/dev/null; then fail "$(rel "$1") should not contain: $2"; else ok; fi; }
assert_eq() { if [ "$1" = "$2" ]; then ok; else fail "$3: expected [$2], got [$1]"; fi; }
assert_status() { assert_eq "$STATUS" "$1" "exit status"; }
assert_no_placeholders() { if grep -rqF --exclude-dir=.git '{{' "$1"; then fail "placeholders left in $(rel "$1")"; else ok; fi; }
count_lines() { grep -cxF -- "$2" "$1" 2>/dev/null || true; }
run_init() { STATUS=0; "$TEST_BASH" "$INIT" "$@" >"$OUT" 2>&1 || STATUS=$?; }

test_help_and_errors() {
  run_init --help
  assert_status 0
  assert_contains "$OUT" "Usage: init.sh"
  run_init --version
  assert_status 0
  assert_contains "$OUT" "0.1.0"
  run_init
  assert_status 2
  run_init "$WORK/x" --bogus
  assert_status 2
  assert_contains "$OUT" "unknown option"
  run_init "$WORK/x" --name
  assert_status 2
  run_init "$WORK/a" "$WORK/b"
  assert_status 2
  assert_absent "$WORK/x"
  assert_absent "$WORK/a"
}

test_new_solo() {
  local d="$WORK/my app" f
  run_init "$d"
  assert_status 0
  for f in $CORE_FILES; do assert_file "$d/$f"; done
  assert_absent "$d/CLAUDE.local.md"
  assert_absent "$d/TEAM.md"
  assert_absent "$d/.claude"
  assert_no_placeholders "$d"
  assert_contains "$d/roadmap.md" "# my app — Roadmap"
  assert_contains "$d/roadmap.md" "$TODAY"
  assert_contains "$d/CLAUDE.md" "## The relay loop: main session and sub-session"
  assert_file "$d/.git/HEAD"
  if git -C "$d" rev-parse -q --verify HEAD >/dev/null; then fail "init.sh must not commit"; else ok; fi
  assert_contains "$OUT" "Read COWORK.md and onboard me."
  assert_contains "$OUT" "Created 11, skipped 0."
}

test_name_with_special_characters() {
  # shellcheck disable=SC2016 # $HOME must stay literal in the project name
  local d="$WORK/special" name='Tom & Jerry'"'"'s "App" $HOME \1 /x/'
  run_init "$d" --name "$name"
  assert_status 0
  assert_contains "$d/roadmap.md" "# $name — Roadmap"
  assert_contains "$d/COWORK.md" "$name"
}

test_existing_project_is_not_overwritten() {
  local d="$WORK/existing"
  mkdir -p "$d"
  printf 'my own rules\n' > "$d/CLAUDE.md"
  printf 'node_modules' > "$d/.gitignore"
  git -C "$d" init -q
  git -C "$d" add -A
  git -C "$d" commit -q -m "initial"
  cp "$d/CLAUDE.md" "$WORK/claude-before"
  run_init "$d"
  assert_status 0
  if cmp -s "$d/CLAUDE.md" "$WORK/claude-before"; then ok; else fail "existing CLAUDE.md was changed"; fi
  assert_contains "$OUT" "skip    CLAUDE.md (already exists)"
  assert_contains "$OUT" "template/CLAUDE.md"
  assert_file "$d/COWORK.md"
  assert_eq "$(git -C "$d" rev-list --count HEAD)" "1" "commit count"
  assert_contains "$OUT" "already a git repository"
  assert_eq "$(cat "$d/.gitignore")" "node_modules" "solo setup leaves .gitignore alone"
}

test_rerun_skips_everything() {
  local d="$WORK/rerun"
  run_init "$d"
  run_init "$d"
  assert_status 0
  assert_lacks "$OUT" "  create  "
  assert_contains "$OUT" "Created 0, skipped 11."
}

test_dry_run_writes_nothing() {
  local d="$WORK/dry" e="$WORK/dry-existing" before after
  run_init "$d" --dry-run
  assert_status 0
  assert_absent "$d"
  assert_contains "$OUT" "Dry run"
  assert_contains "$OUT" "  create  COWORK.md"
  assert_contains "$OUT" "Dry run: would create 11, skip 0."
  mkdir -p "$e"
  printf 'x\n' > "$e/CLAUDE.md"
  before="$(cd "$e" && find . | LC_ALL=C sort)"
  run_init "$e" --dry-run
  after="$(cd "$e" && find . | LC_ALL=C sort)"
  assert_eq "$after" "$before" "files after dry run"
}

test_refuses_bad_targets() {
  run_init "$ROOT"
  assert_status 2
  assert_contains "$OUT" "inside the scaffold"
  run_init "$ROOT/new-sub"
  assert_status 2
  assert_absent "$ROOT/new-sub"
  printf 'x' > "$WORK/a-file"
  run_init "$WORK/a-file"
  assert_status 2
  assert_contains "$OUT" "not a directory"
}

test_relative_target() {
  mkdir -p "$WORK/cwd"
  STATUS=0
  (cd "$WORK/cwd" && "$TEST_BASH" "$INIT" rel/proj >"$OUT" 2>&1) || STATUS=$?
  assert_status 0
  assert_file "$WORK/cwd/rel/proj/COWORK.md"
}

test_inside_existing_repo() {
  local mono="$WORK/mono"
  mkdir -p "$mono"
  git -C "$mono" init -q
  run_init "$mono/packages/app"
  assert_status 0
  assert_file "$mono/packages/app/COWORK.md"
  assert_absent "$mono/packages/app/.git"
}

test_team_new() {
  local d="$WORK/team" f
  run_init "$d" --team --name "Team App"
  assert_status 0
  for f in $CORE_FILES $TEAM_FILES; do assert_file "$d/$f"; done
  assert_contains "$d/CLAUDE.md" "# Team rules — Team App"
  assert_contains "$d/CLAUDE.local.md" "## The relay loop: main session and sub-session"
  assert_eq "$(count_lines "$d/.gitignore" "CLAUDE.local.md")" "1" "CLAUDE.local.md lines in .gitignore"
  assert_no_placeholders "$d"
  assert_contains "$OUT" "Created 15, skipped 0."
  run_init "$d" --team
  assert_status 0
  assert_lacks "$OUT" "  create  "
  assert_lacks "$OUT" "mv CLAUDE.md CLAUDE.local.md"
  assert_eq "$(count_lines "$d/.gitignore" "CLAUDE.local.md")" "1" "CLAUDE.local.md lines after rerun"
}

test_team_gitignore_without_trailing_newline() {
  local d="$WORK/team-gi"
  mkdir -p "$d"
  printf 'node_modules' > "$d/.gitignore"
  run_init "$d" --team
  assert_status 0
  assert_eq "$(count_lines "$d/.gitignore" "node_modules")" "1" "node_modules line"
  assert_eq "$(count_lines "$d/.gitignore" "CLAUDE.local.md")" "1" "CLAUDE.local.md line"
}

test_team_after_solo() {
  local d="$WORK/solo-then-team"
  run_init "$d"
  run_init "$d" --team
  assert_status 0
  assert_contains "$OUT" "mv CLAUDE.md CLAUDE.local.md"
  assert_contains "$d/CLAUDE.md" "## The relay loop: main session and sub-session"
  mv "$d/CLAUDE.md" "$d/CLAUDE.local.md"
  run_init "$d" --team
  assert_status 0
  assert_contains "$d/CLAUDE.md" "# Team rules"
  assert_lacks "$OUT" "mv CLAUDE.md CLAUDE.local.md"
}

while IFS= read -r t; do
  printf '%s\n' "$t"
  "$t"
done < <(declare -F | awk '{print $3}' | grep '^test_' | grep -F -- "${1:-test_}")

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
