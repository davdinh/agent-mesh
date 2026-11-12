#!/usr/bin/env bash
# mesh.sh - one-command code-review "agent mesh" on top of T3 Code.
#
# Usage:  ./mesh.sh <project-folder> ["what to focus on"]
#
# What it does:
#   1. Starts 3 read-only reviewer threads in T3 Code, in parallel (bugs, security, quality).
#   2. Saves each reviewer's report to shared/<run-id>/<role>.md
#   3. Starts a 4th "lead" thread that merges the reports into shared/<run-id>/summary.md
#
# The agents are ASKED to be read-only (see prompts/*.txt), and THIS SCRIPT is what
# writes the report files, so a normal run never needs a file edit. If an agent
# did try to edit something, T3's permission mode for the project is what stops it
# and asks you in the app. Keep that project in "Supervised" mode.
#
# Requirements: T3 Code desktop app is running, and <project-folder> is (inside)
# a project already added in the T3 app.

set -u

T3='C:\Users\dadinh\.t3\bin\t3.cmd'
PROVIDER="claudeAgent"
WORKER_MODEL="claude-haiku-5-5"   # cheap model for the 3 reviewers
LEAD_MODEL="claude-opus-5-5"      # stronger model for the final summary

HERE="$(cd "$(dirname "$0")" && pwd)"

die() { echo "ERROR: $*" >&2; exit 1; }

# ---- 1. check inputs --------------------------------------------------------
TARGET="${1:-}"
FOCUS="${2:-general review}"
[ -n "$TARGET" ] || die "no folder given. Usage: ./mesh.sh <project-folder> [\"focus\"]"
[ -d "$TARGET" ] || die "folder not found: $TARGET"
[ -f "$(cygpath -u "$T3")" ] || die "T3 command-line tool not found at $T3 (is T3 Code installed and opened once?)"
for role in bugs security quality summary; do
  [ -f "$HERE/prompts/$role.txt" ] || die "missing prompt file: prompts/$role.txt"
done

TARGET="$(cd "$TARGET" && pwd)"
WINTARGET="$(cygpath -w "$TARGET")"
RUN_ID="$(date +%Y%m%d-%H%M%S)"
OUT="$HERE/shared/$RUN_ID"
TMP="$(mktemp -d)"
mkdir -p "$OUT"
trap 'rm -rf "$TMP"' EXIT

echo "Run $RUN_ID"
echo "Reviewing: $WINTARGET"
echo "Focus:     $FOCUS"
echo "Reports:   $OUT"
echo

# ---- 2. helper: run one agent thread ---------------------------------------
# run_agent <role> <model> <prompt-text>
# Writes the reply to $TMP/<role>.out and the exit code to $TMP/<role>.rc
#   rc 0 = ok, 1 = agent run failed, 2 = agent is waiting for you to answer in the app
#   (these codes come from `t3 thread start --help`: "Exits 1 if the run fails and 2 if it waits for an answer")
run_agent() {
  local role="$1" model="$2" prompt="$3"
  # Run from inside the target folder and pass "." so folder names with spaces are safe.
  # (The T3 path has no spaces, so it needs no quotes.)
  ( cd "$TARGET" && printf '%s' "$prompt" | cmd.exe //c "$T3 thread start --provider $PROVIDER --model $model --title mesh-$RUN_ID-$role --wait . -" ) > "$TMP/$role.raw" 2>&1
  echo $? > "$TMP/$role.rc"
  # drop the first "Thread <id>" line, keep the agent's reply
  sed '1{/^Thread /d}' "$TMP/$role.raw" > "$TMP/$role.out"
}

# ---- 3. run the three reviewers in parallel --------------------------------
for role in bugs security quality; do
  prompt="$(cat "$HERE/prompts/$role.txt")

Focus for this review: $FOCUS

SCOPE: review ONLY the files inside this folder (and its subfolders): $WINTARGET
Ignore every file outside that folder, even if you can see it."
  echo "Starting $role reviewer..."
  run_agent "$role" "$WORKER_MODEL" "$prompt" &
done
wait
echo

ok=0
REPORTS=""
for role in bugs security quality; do
  rc="$(cat "$TMP/$role.rc" 2>/dev/null || echo 1)"
  case "$rc" in
    0)
      {
        echo "# ${role} review"
        echo
        echo "_Run ${RUN_ID}, focus: ${FOCUS}_"
        echo
        cat "$TMP/$role.out"
      } > "$OUT/$role.md"
      REPORTS="$REPORTS
=== REPORT FROM $role REVIEWER ===
$(cat "$TMP/$role.out")
"
      ok=$((ok + 1))
      echo "  [ok]      $role -> $OUT/$role.md"
      ;;
    2) echo "  [waiting] $role is waiting for an answer or approval in the T3 app (thread mesh-$RUN_ID-$role)" ;;
    *) echo "  [failed]  $role: $(head -c 300 "$TMP/$role.raw")" ;;
  esac
done

if [ "$ok" -eq 0 ]; then
  rmdir "$OUT" 2>/dev/null   # remove the empty run folder
  die "no reviewer finished successfully, so there is nothing to summarize."
fi

# ---- 4. lead reviewer writes the summary -----------------------------------
echo
echo "Starting lead reviewer..."
lead_prompt="$(cat "$HERE/prompts/summary.txt")

--- BEGIN REPORTS ---
$REPORTS
--- END REPORTS ---"
run_agent "lead" "$LEAD_MODEL" "$lead_prompt"

if [ "$(cat "$TMP/lead.rc" 2>/dev/null || echo 1)" = "0" ]; then
  {
    echo "# Summary"
    echo
    echo "_Run ${RUN_ID}, focus: ${FOCUS}, reviewed: ${WINTARGET}_"
    echo
    cat "$TMP/lead.out"
  } > "$OUT/summary.md"
  echo "  [ok]      summary -> $OUT/summary.md"
else
  echo "  [failed]  lead summary: $(head -c 300 "$TMP/lead.raw")"
  echo "  The three individual reports above were still saved."
  exit 1
fi

echo
echo "Done. Open: $OUT/summary.md"
