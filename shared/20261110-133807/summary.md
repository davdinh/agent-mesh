# Summary

_Run 20261110-133807, focus: check everything, reviewed: C:\Users\dadinh\agent-mesh\sample_

# Lead review summary: `agent-mesh`

**Verdict:** `sample/buggy.js` has one real security hole and one bug that makes a function always return the wrong answer, so fix those first. `mesh.sh` works, but it claims its agents are read-only when nothing actually forces them to be.

## Top issues, fix first to last

1. **SQL injection in `findUser`** (`sample/buggy.js:17`). Flagged by all three reviewers.
   - **Why it matters:** The user's `name` is pasted straight into the SQL text. SQL injection means someone types input that changes the query itself. For example, `' OR '1'='1` returns every user, and a name containing `'` breaks the query.
   - **Fix:** Use a parameterized query, which sends the value separately from the SQL text: `db.run("SELECT * FROM users WHERE name = ?", [name])`. Also, the quality reviewer points out that `db.run` usually doesn't return rows, so use `get` or `all` (check what your database library calls them) and handle errors.

2. **`average()` always returns `NaN`** (`sample/buggy.js:9`, and `:12` for the empty case). Flagged by bugs and quality.
   - **Why it matters:** The loop uses `i <= numbers.length`, so it reads one slot past the end. That slot is `undefined`, which turns the sum into `NaN` ("not a number"). An empty array also gives `0/0`, which is `NaN`.
   - **Fix:** Change the condition to `i < numbers.length`. If the array is empty, return `0` or throw a clear error. Optionally reject entries that aren't numbers.

3. **API key hard-coded and printed to the console** (`sample/buggy.js:4` and `:33`). Flagged by all three.
   - **Why it matters:** The key (`sk-F...`) is written directly in the source, and line 33 prints it every time the file is loaded, so it ends up in logs. The comment says it's a fake placeholder, but this is the habit that leaks real keys.
   - **Fix:** Delete the `console.log` line. Read the key from an environment variable. If a real key was ever committed, replace it with a new one.

4. **The "read-only" agents aren't actually locked down** (`mesh.sh:11` comment, `mesh.sh:60` `thread start`). Flagged by security and quality.
   - **Why it matters:** The only thing keeping reviewers read-only is an instruction in their prompt. A reviewer could be tricked by text inside the files it's reviewing (this is called prompt injection) into editing files or running commands.
   - **Fix:** Pass the most restrictive runtime mode the T3 CLI supports. If you can't, change the comment to say the agents are *asked* to be read-only.

5. **`formatPrice` and `formatCost` crash on bad input and are copies of each other** (`sample/buggy.js:21-27`). Flagged by bugs and quality.
   - **Fix:** Check the input with `Number.isFinite` before calling `.toFixed`. Keep one function and delete the copy.

6. **Exit code 2 is assumed to mean "waiting for the user", but nobody has confirmed it** (`mesh.sh:55`, `:60`, `:98`). Flagged by bugs and quality.
   - **Why it matters:** If the CLI uses a different code, the "waiting" branch never runs.
   - **Fix:** Look up the CLI's exit codes and note them in a comment, or check the output text as well.

7. **Reports may contain secrets and could be committed** (`mesh.sh:63`, `:91-94`). Flagged by security and quality.
   - **Fix:** Add `shared/` to a `.gitignore` file. Shorten any secrets before writing reports.

8. **Lower-priority cleanup** (quality reviewer):
   - Keep stderr (error output) separate from the saved report (`mesh.sh:60,63`).
   - Allow the hard-coded T3 path and model IDs to be overridden.
   - Document that the script needs `cygpath`, which only exists in Git Bash.
   - Move the duplicated exit-code and report-writing code into helper functions.
   - Put the rules block that's copied into all three prompt files into one shared file.
   - Delete `unusedHelper`.
   - Add tests and a README.

## Disagreements and possible false alarms

- **API key severity:** Security rated it medium, quality rated it low, and bugs said it wasn't a bug. All three agree the key is a placeholder, so it's not an emergency. The log line is still worth deleting now.
- **Exit code 2:** Bugs rated it low and quality rated it medium. Neither could confirm the convention, so treat it as "needs checking" rather than a known bug.
- **Read-only enforcement:** Bugs said `mesh.sh` looked fine, but they were only looking for logic errors. Security and quality's finding still stands.
- **Coverage gap:** The bugs reviewer didn't read three of the prompt files (`bugs.txt`, `security.txt`, `quality.txt`). The other two did and found nothing dangerous in them.
- **File count:** Security reported 7 files and quality reported 6. It's a small mismatch with no impact on the findings.
- **Shell injection:** Security checked whether the `$FOCUS` argument could inject shell commands and found it can't, because it is passed through stdin rather than into the command line. That's correctly a non-issue.
- None of the reports tried to give the reviewers instructions.
