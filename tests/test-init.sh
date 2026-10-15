#!/usr/bin/env bash
# Black-box tests for init.sh. Run: tests/test-init.sh [name-filter]
# test_* functions run once per language (--lang en, then --lang zh); once_* functions run once.
# On macOS, run with TEST_BASH=/bin/bash to exercise the system bash 3.2.
# shellcheck disable=SC2317,SC2329 # the tests are called by name from run_tests
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
INIT="$ROOT/init.sh"
TEST_BASH="${TEST_BASH:-bash}"
TODAY="$(date +%F)"
BASE="$(mktemp -d "${TMPDIR:-/tmp}/relay-loop-test.XXXXXX")"
BASE="$(cd "$BASE" && pwd -P)"
trap 'rm -rf "$BASE"' EXIT

# Keep the user's git config (signing, hooks, default branch) out of the tests.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export GIT_AUTHOR_NAME=test GIT_AUTHOR_EMAIL=test@example.com
export GIT_COMMITTER_NAME=test GIT_COMMITTER_EMAIL=test@example.com

CORE_FILES="COWORK.md CLAUDE.md roadmap.md features/README.md features/_template/plan.md pipe/README.md pipe/cowork/latest.md pipe/cowork/log/.gitkeep pipe/claudecode/latest.md pipe/claudecode/log/.gitkeep pipe/claudecode/plans/README.md"
TEAM_FILES="CLAUDE.local.md TEAM.md features/_template/task-card.md .github/pull_request_template.md"
RULES_MARKER="<!-- relay-loop:rules -->"
LANGS="en zh"

# Set per language by the runner at the bottom; once_* tests see the English values.
L=en                            # value for --lang
LDIR=en                         # its folder under template/, addons/team/ and messages/
TPL="$ROOT/template/en"
TEAM_TPL="$ROOT/addons/team/en"
WORK="$BASE/once"

PASS=0
FAIL=0
STATUS=0
OUT="$BASE/out.txt"

ok() { PASS=$((PASS + 1)); }
fail() { printf '    FAIL: %s\n' "$*"; FAIL=$((FAIL + 1)); }
rel() { local p="${1#"$BASE"/}"; printf '%s' "${p#"$ROOT"/}"; }
assert_file() { if [ -f "$1" ]; then ok; else fail "missing file: $(rel "$1")"; fi; }
assert_absent() { if [ ! -e "$1" ]; then ok; else fail "should not exist: $(rel "$1")"; fi; }
assert_contains() { if grep -qF -- "$2" "$1" 2>/dev/null; then ok; else fail "$(rel "$1") should contain: $2"; fi; }
assert_lacks() { if grep -qF -- "$2" "$1" 2>/dev/null; then fail "$(rel "$1") should not contain: $2"; else ok; fi; }
assert_eq() { if [ "$1" = "$2" ]; then ok; else fail "$3: expected [$2], got [$1]"; fi; }
assert_status() { assert_eq "$STATUS" "$1" "exit status"; }
assert_no_placeholders() { if grep -rqF --exclude-dir=.git '{{' "$1"; then fail "placeholders left in $(rel "$1")"; else ok; fi; }
count_lines() { grep -cxF -- "$2" "$1" 2>/dev/null || true; }
lang_dir() { case "$1" in zh) echo zh-CN ;; *) echo "$1" ;; esac; }
run_init_bare() { STATUS=0; "$TEST_BASH" "$INIT" "$@" >"$OUT" 2>&1 || STATUS=$?; }
run_init_lang() { local lang="$1"; shift; run_init_bare --lang "$lang" "$@"; }
run_init() { run_init_lang "$L" "$@"; }

# Every file under $1 except .git/, one relative path per line, sorted.
list_files() { (cd "$1" && find . -type f ! -path './.git/*' ! -name .DS_Store | sed 's|^\./||' | LC_ALL=C sort); }
assert_files_exactly() { assert_eq "$(list_files "$1")" "$(printf '%s' "$2" | tr ' ' '\n' | LC_ALL=C sort)" "files in $(rel "$1")"; }

# $1 with the placeholders filled in, the way init.sh should write it.
# shellcheck disable=SC2016 # $ENV{...} is perl, not shell
render() { RL_NAME="$2" RL_DATE="$TODAY" perl -pe 's/\{\{PROJECT_NAME\}\}/$ENV{RL_NAME}/g; s/\{\{DATE\}\}/$ENV{RL_DATE}/g' "$1"; }
assert_rendered() { if render "$2" "$3" | cmp -s - "$1"; then ok; else fail "$(rel "$1") is not $(rel "$2") with the placeholders filled in"; fi; }

# init.sh ends with messages/<lang>.txt, <folder> replaced by the project folder ($1).
assert_next_steps() {
  local line
  while IFS= read -r line; do
    case "$line" in
      *"<folder>"*) line="${line%%<folder>*}$1${line#*<folder>}" ;;
    esac
    assert_contains "$OUT" "$line"
  done <"$ROOT/messages/$LDIR.txt"
}

placeholders() { grep -oE '\{\{[A-Za-z_]+\}\}' "$1" | LC_ALL=C sort | uniq -c; }

once_help_and_errors() {
  run_init_bare --help
  assert_status 0
  assert_contains "$OUT" "Usage: init.sh"
  assert_contains "$OUT" "--lang <en|zh>"
  run_init_bare --version
  assert_status 0
  assert_contains "$OUT" "0.1.0"
  run_init_bare
  assert_status 2
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

once_lang_option() {
  local d="$WORK/default-lang" z="$WORK/lang-equals" bad="$WORK/bad-lang" v
  run_init_bare "$d"
  assert_status 0
  assert_rendered "$d/COWORK.md" "$ROOT/template/en/COWORK.md" "default-lang"
  assert_next_steps "$d"
  run_init_bare "$z" --lang=zh
  assert_status 0
  assert_rendered "$z/COWORK.md" "$ROOT/template/zh-CN/COWORK.md" "lang-equals"
  for v in fr zh-CN EN ""; do
    run_init_bare "$bad" --lang "$v"
    assert_status 2
    assert_contains "$OUT" "unknown language"
  done
  run_init_bare "$bad" --lang
  assert_status 2
  assert_absent "$bad"
}

once_languages_match() {
  local part f en zh ldir
  for part in template addons/team; do
    en="$(list_files "$ROOT/$part/en")"
    zh="$(list_files "$ROOT/$part/zh-CN")"
    assert_eq "$zh" "$en" "files in $part/zh-CN compared with $part/en"
    while IFS= read -r f; do
      [ -f "$ROOT/$part/zh-CN/$f" ] || continue
      assert_eq "$(placeholders "$ROOT/$part/zh-CN/$f")" "$(placeholders "$ROOT/$part/en/$f")" "placeholders in $part/zh-CN/$f"
    done < <(printf '%s\n' "$en")
  done
  if grep -rhoE '\{\{[^}]*\}\}' "$ROOT/template" "$ROOT/addons" | grep -vxE '\{\{(PROJECT_NAME|DATE)\}\}' >/dev/null; then
    fail "template/ or addons/ use a placeholder other than {{PROJECT_NAME}} and {{DATE}}"
  else
    ok
  fi
  for ldir in en zh-CN; do
    assert_eq "$(count_lines "$ROOT/template/$ldir/CLAUDE.md" "$RULES_MARKER")" "1" "rules marker lines in template/$ldir/CLAUDE.md"
    assert_lacks "$ROOT/addons/team/$ldir/CLAUDE.md" "$RULES_MARKER"
    assert_eq "$(wc -l <"$ROOT/messages/$ldir.txt" | tr -d ' ')" "4" "lines in messages/$ldir.txt"
    assert_contains "$ROOT/messages/$ldir.txt" "<folder>"
  done
}

# What init.sh tells the owner to say to Cowork is what COWORK.md and pipe/cowork/latest.md expect.
once_opener_matches_cowork_md() {
  local ldir opener
  for ldir in en zh-CN; do
    opener="$(sed -n 3p "$ROOT/messages/$ldir.txt" | perl -CSD -pe 's/^.*[:\x{FF1A}]\s*//; s/\.$//')"
    case "$opener" in
      *COWORK.md*) ok ;;
      *) fail "no opener after the colon on line 3 of messages/$ldir.txt" ;;
    esac
    assert_contains "$ROOT/template/$ldir/COWORK.md" "$opener"
    assert_contains "$ROOT/template/$ldir/pipe/cowork/latest.md" "$opener"
  done
}

once_rerun_in_the_other_language() {
  local d="$WORK/other-lang"
  run_init_lang en "$d"
  run_init_lang zh "$d"
  assert_status 0
  assert_contains "$OUT" "this project was set up with --lang en"
  assert_lacks "$OUT" "  create  "
  assert_lacks "$OUT" "doesn't have the relay-loop rules"
  assert_contains "$OUT" "Created 0, skipped 11."
}

# Without --lang, a project that was set up before keeps its language.
once_lang_follows_the_project() {
  local d="$WORK/zh-then-team" e="$WORK/en-rerun"
  run_init_lang zh "$d" --name "zh then team"
  run_init_bare "$d" --team --name "zh then team"
  assert_status 0
  assert_contains "$OUT" "--lang zh: the language this project was set up in"
  assert_rendered "$d/TEAM.md" "$ROOT/addons/team/zh-CN/TEAM.md" "zh then team"
  assert_rendered "$d/CLAUDE.local.md" "$ROOT/template/zh-CN/CLAUDE.md" "zh then team"
  assert_contains "$OUT" "--team --lang zh --name 'zh then team'"
  run_init_lang en "$e"
  run_init_bare "$e"
  assert_status 0
  assert_lacks "$OUT" "  note    "
}

once_refuses_bad_targets() {
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

once_relative_target() {
  mkdir -p "$WORK/cwd"
  STATUS=0
  (cd "$WORK/cwd" && "$TEST_BASH" "$INIT" rel/proj >"$OUT" 2>&1) || STATUS=$?
  assert_status 0
  assert_file "$WORK/cwd/rel/proj/COWORK.md"
}

once_inside_existing_repo() {
  local mono="$WORK/mono"
  mkdir -p "$mono"
  git -C "$mono" init -q
  run_init "$mono/packages/app"
  assert_status 0
  assert_file "$mono/packages/app/COWORK.md"
  assert_absent "$mono/packages/app/.git"
}

once_team_gitignore_without_trailing_newline() {
  local d="$WORK/team-gi"
  mkdir -p "$d"
  printf 'node_modules' > "$d/.gitignore"
  run_init "$d" --team
  assert_status 0
  assert_eq "$(count_lines "$d/.gitignore" "node_modules")" "1" "node_modules line"
  assert_eq "$(count_lines "$d/.gitignore" "CLAUDE.local.md")" "1" "CLAUDE.local.md line"
}

once_no_attribution() {
  local d="$WORK/attr" e="$WORK/attr-existing"
  run_init "$d" --no-attribution
  assert_status 0
  if jq -e '.attribution.commit == "" and .attribution.pr == ""' "$d/.claude/settings.json" >/dev/null 2>&1; then ok; else fail "settings.json attribution"; fi
  mkdir -p "$e/.claude"
  printf '{"x": 1}\n' > "$e/.claude/settings.json"
  run_init "$e" --no-attribution
  assert_status 0
  assert_eq "$(cat "$e/.claude/settings.json")" '{"x": 1}' "existing settings.json"
  assert_contains "$OUT" '"attribution"'
}

once_auto_push_setup() {
  local d="$WORK/push" e="$WORK/push-existing"
  run_init "$d" --auto-push
  assert_status 0
  if jq -e '.hooks.PostToolUse[0].matcher == "Bash" and (.hooks.PostToolUse[0].hooks[0].command | contains(".claude/hooks/auto-push.sh"))' "$d/.claude/settings.local.json" >/dev/null 2>&1; then ok; else fail "settings.local.json hook"; fi
  if [ -x "$d/.claude/hooks/auto-push.sh" ]; then ok; else fail "auto-push.sh is not executable"; fi
  assert_eq "$(count_lines "$d/.gitignore" ".claude/settings.local.json")" "1" "settings.local.json in .gitignore"
  mkdir -p "$e/.claude"
  printf '{}\n' > "$e/.claude/settings.local.json"
  run_init "$e" --auto-push
  assert_status 0
  assert_eq "$(cat "$e/.claude/settings.local.json")" '{}' "existing settings.local.json"
  assert_contains "$OUT" "PostToolUse"
}

once_auto_push_hook_pushes() {
  local d="$WORK/hook" remote="$WORK/hook-remote.git" out branch
  git init -q --bare "$remote"
  run_init "$d" --auto-push
  git -C "$d" remote add origin "$remote"
  printf 'x\n' > "$d/x.txt"
  git -C "$d" add x.txt
  git -C "$d" commit -q -m "test commit"
  branch="$(git -C "$d" symbolic-ref --short HEAD)"
  out="$(printf '%s' '{"tool_input":{"command":"git commit -m test"}}' | CLAUDE_PROJECT_DIR="$d" "$TEST_BASH" "$d/.claude/hooks/auto-push.sh")"
  assert_eq "$(git -C "$remote" rev-parse "refs/heads/$branch" 2>/dev/null)" "$(git -C "$d" rev-parse HEAD)" "remote branch after the hook"
  case "$(printf '%s' "$out" | jq -r .systemMessage)" in
    "auto push:"*) ok ;;
    *) fail "hook message: $out" ;;
  esac
  out="$(printf '%s' '{"tool_input":{"command":"ls -la"}}' | CLAUDE_PROJECT_DIR="$d" "$TEST_BASH" "$d/.claude/hooks/auto-push.sh")"
  assert_eq "$out" "" "hook output for a command that isn't a commit"
}

test_new_solo() {
  local d="$WORK/my app" f
  run_init "$d"
  assert_status 0
  assert_files_exactly "$d" "$CORE_FILES"
  for f in $CORE_FILES; do assert_rendered "$d/$f" "$TPL/$f" "my app"; done
  assert_no_placeholders "$d"
  assert_contains "$d/roadmap.md" "my app"
  assert_contains "$d/roadmap.md" "$TODAY"
  assert_contains "$d/CLAUDE.md" "$RULES_MARKER"
  assert_file "$d/.git/HEAD"
  if git -C "$d" rev-parse -q --verify HEAD >/dev/null; then fail "init.sh must not commit"; else ok; fi
  assert_next_steps "$d"
  assert_contains "$OUT" "Created 11, skipped 0."
}

test_name_with_special_characters() {
  # shellcheck disable=SC2016 # $HOME must stay literal in the project name
  local d="$WORK/special" name='Tom & Jerry'"'"'s "App" $HOME \1 /x/'
  run_init "$d" --name "$name"
  assert_status 0
  case "$(head -n 1 "$d/roadmap.md")" in
    "# $name — "*) ok ;;
    *) fail "roadmap.md title: $(head -n 1 "$d/roadmap.md")" ;;
  esac
  assert_contains "$d/COWORK.md" "$name"
  assert_rendered "$d/COWORK.md" "$TPL/COWORK.md" "$name"
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
  assert_contains "$OUT" "$TPL/CLAUDE.md"
  assert_contains "$OUT" "doesn't have the relay-loop rules"
  assert_file "$d/COWORK.md"
  assert_eq "$(git -C "$d" rev-list --count HEAD)" "1" "commit count"
  assert_contains "$OUT" "already a git repository"
  assert_eq "$(cat "$d/.gitignore")" "node_modules" "solo setup leaves .gitignore alone"
}

test_existing_rules_are_recognized() {
  local d="$WORK/merged-rules"
  mkdir -p "$d"
  printf '# Our rules\n\n%s\n' "$RULES_MARKER" > "$d/CLAUDE.md"
  run_init "$d"
  assert_status 0
  assert_contains "$OUT" "skip    CLAUDE.md (already exists)"
  assert_lacks "$OUT" "doesn't have the relay-loop rules"
}

test_rerun_skips_everything() {
  local d="$WORK/rerun"
  run_init "$d"
  run_init "$d"
  assert_status 0
  assert_lacks "$OUT" "  create  "
  assert_lacks "$OUT" "doesn't have the relay-loop rules"
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
  assert_lacks "$OUT" "$(head -n 1 "$ROOT/messages/$LDIR.txt")"
  mkdir -p "$e"
  printf 'x\n' > "$e/CLAUDE.md"
  before="$(cd "$e" && find . | LC_ALL=C sort)"
  run_init "$e" --dry-run
  after="$(cd "$e" && find . | LC_ALL=C sort)"
  assert_eq "$after" "$before" "files after dry run"
}

test_team_new() {
  local d="$WORK/team" f
  run_init "$d" --team --name "Team App"
  assert_status 0
  assert_files_exactly "$d" "$CORE_FILES $TEAM_FILES .gitignore"
  assert_rendered "$d/CLAUDE.md" "$TEAM_TPL/CLAUDE.md" "Team App"
  assert_rendered "$d/CLAUDE.local.md" "$TPL/CLAUDE.md" "Team App"
  for f in TEAM.md features/_template/task-card.md .github/pull_request_template.md; do
    assert_rendered "$d/$f" "$TEAM_TPL/$f" "Team App"
  done
  assert_contains "$d/CLAUDE.local.md" "$RULES_MARKER"
  assert_eq "$(count_lines "$d/.gitignore" "CLAUDE.local.md")" "1" "CLAUDE.local.md lines in .gitignore"
  assert_no_placeholders "$d"
  assert_contains "$OUT" "Created 15, skipped 0."
  run_init "$d" --team
  assert_status 0
  assert_lacks "$OUT" "  create  "
  assert_lacks "$OUT" "switch with:"
  assert_eq "$(count_lines "$d/.gitignore" "CLAUDE.local.md")" "1" "CLAUDE.local.md lines after rerun"
}

test_team_after_solo() {
  local d="$WORK/solo-then-team"
  run_init "$d"
  run_init "$d" --team
  assert_status 0
  assert_contains "$OUT" "switch with:"
  assert_contains "$d/CLAUDE.md" "$RULES_MARKER"
  mv "$d/CLAUDE.md" "$d/CLAUDE.local.md"
  run_init "$d" --team
  assert_status 0
  assert_rendered "$d/CLAUDE.md" "$TEAM_TPL/CLAUDE.md" "solo-then-team"
  assert_lacks "$OUT" "switch with:"
}

test_team_switch_hint_works_from_another_folder() {
  # A path with a space and a quote, and a name with non-ASCII letters (two Chinese characters, as UTF-8 bytes).
  local d="$WORK/switch it's" other="$WORK/switch-cwd" hint name
  name="Switch $(printf '\346\265\213\350\257\225')"
  mkdir -p "$other"
  printf 'unrelated\n' > "$other/CLAUDE.md"
  run_init "$d" --name "$name"
  run_init "$d" --team --name "$name"
  assert_contains "$OUT" "--name '$name'"
  hint="$(grep -A1 -F 'switch with:' "$OUT" | tail -n 1)"
  STATUS=0
  (cd "$other" && eval "$hint") >/dev/null 2>&1 || STATUS=$?
  assert_status 0
  assert_eq "$(cat "$other/CLAUDE.md" 2>/dev/null)" "unrelated" "CLAUDE.md in the folder the hint ran from"
  assert_rendered "$d/CLAUDE.md" "$TEAM_TPL/CLAUDE.md" "$name"
  assert_rendered "$d/CLAUDE.local.md" "$TPL/CLAUDE.md" "$name"
}

FILTER="${1:-}"
run_tests() {
  local t
  while IFS= read -r t; do
    printf '%s\n' "$t"
    "$t"
  done < <(declare -F | awk '{print $3}' | grep "^$1" | grep -F -- "$FILTER")
}

mkdir -p "$WORK"
run_tests once_
for L in $LANGS; do
  LDIR="$(lang_dir "$L")"
  TPL="$ROOT/template/$LDIR"
  TEAM_TPL="$ROOT/addons/team/$LDIR"
  WORK="$BASE/$L"
  mkdir -p "$WORK"
  printf -- '--lang %s\n' "$L"
  run_tests test_
done

printf '\n%d passed, %d failed\n' "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ]
