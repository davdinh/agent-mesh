# security review

_Run 20261110-133936, focus: check everything_

**Security review: `C:\Users\dadinh\agent-mesh\sample`**

Scope: the folder contains one file, `buggy.js`. Glob skips dotfiles, so I didn't check for hidden config files there. The file's own header says its contents are planted test problems and the key is a placeholder. I reported the findings anyway.

- `buggy.js:4` | high | Hardcoded API key in source (`sk-F...`, full value withheld). Anything that can read the file has the credential, and it will sit in version history. | Load the key from an environment variable or secret store, and rotate it if the value was ever real.
- `buggy.js:33` | high | The key is written to stdout with `console.log("Debug key: " + API_KEY)`, which leaks it into logs and terminal output. | Remove the log line. Never log credentials, and mask any secret that must appear in diagnostics.
- `buggy.js:17-18` | high | SQL injection. `name` is concatenated straight into the query string passed to `db.run`, so input like `' OR '1'='1` changes the query. There is also no validation of `name`. | Use a parameterized query, e.g. `db.run("SELECT * FROM users WHERE name = ?", [name])`, and validate the input type and length.

No other security issues in this file. The rest is correctness, not security: `average` at line 9 uses `i <= numbers.length`, which reads one element past the end and yields `NaN` for the sum; `formatPrice` and `formatCost` at lines 21-27 are duplicates; and `unusedHelper` at line 29 is dead code.
