# security review

_Run 20261110-135512, focus: check everything_

The sample folder contains one file, `sample\buggy.js`, so that is the only file I reviewed. Read-only, nothing edited or run.

`sample\buggy.js:4` | high | Hardcoded API key `sk-F...` in source. The file's own comment says it is a placeholder, but the pattern is the same one a real key would use. | Load the key from an environment variable or secret store and fail fast if it is missing.

`sample\buggy.js:17-18` | high | SQL injection. `name` is concatenated into the query string and passed to `db.run`, so a value like `' OR '1'='1` changes the query. | Use a parameterized query, e.g. `db.run("SELECT * FROM users WHERE name = ?", [name])`, and validate `name` as a string.

`sample\buggy.js:33` | high | Logs the API key to the console in plaintext. | Remove the log line, or log only a masked value.

`sample\buggy.js:16` | low | `findUser` does no input validation or authorization check on `name`. | Validate the type and length of `name`, and enforce the caller's access rights before returning user records.

Not security, noted in passing: `sample\buggy.js:9` loops with `i <= numbers.length`, an off-by-one that reads `undefined` on the last iteration.
