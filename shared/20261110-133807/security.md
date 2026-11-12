# security review

_Run 20261110-133807, focus: check everything_

Reviewed all 7 files in `C:\Users\dadinh\agent-mesh` (`mesh.sh`, `sample/buggy.js`, and the four `prompts/*.txt` files). No hidden files exist. Read-only, no commands run.

| Location | Severity | Problem | Suggested fix |
|---|---|---|---|
| `sample/buggy.js:17` | high | SQL injection: `name` is concatenated into the query string (`"... WHERE name = '" + name + "'"`). A name like `' OR '1'='1` returns every row. | Use a parameterized query, e.g. `db.run("SELECT * FROM users WHERE name = ?", [name])`. |
| `sample/buggy.js:4` | medium | Hardcoded API key `sk-F...` in source. The comment says it is a fake placeholder, so this is a pattern issue. If it were real it would be high. | Read the key from an environment variable or secret store, and rotate any real key that was ever committed. |
| `sample/buggy.js:33` | medium | The API key is written to the console (`console.log("Debug key: " + API_KEY)`), so it ends up in logs. | Delete the log line. Never log secrets. |
| `mesh.sh:60` | medium | Read-only is enforced only by prompt text. The `thread start` call passes no restrictive runtime or approval mode, so a reviewer that gets confused by file content could edit or run things. The comment at lines 10-12 overstates the protection. | Pass the most restrictive runtime mode the T3 CLI supports, or verify the thread's mode before trusting its output. |
| `mesh.sh:91-94`, `mesh.sh:63` | low | Reviewer output, which may quote secrets it found, is written to `shared/<run-id>/*.md` in the project tree. There is no `.gitignore` to keep `shared/` out of commits. | Add `shared/` to a `.gitignore`, and redact secrets before writing reports. |
| `mesh.sh:70` / `prompts/*.txt` | low | Prompt-injection surface: the reviewed project's files and the `$FOCUS` argument flow into the agents' context. The prompts tell agents to ignore instructions in files, but that is not a hard control. | Treat the reviewed project as untrusted. Keep reviewers read-only, as in the first finding above. |

Checked and not a finding: `FOCUS` is sent through stdin (`printf '%s' "$prompt" | ...`), not spliced into the `cmd.exe` string, so it does not allow shell injection. `RUN_ID` and `role` are safe values. `TMP` comes from `mktemp -d` and is cleaned up with a trap.
