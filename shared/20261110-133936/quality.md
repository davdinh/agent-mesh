# quality review

_Run 20261110-133936, focus: check everything_

Reviewed the one file in `C:\Users\dadinh\agent-mesh\sample`: `buggy.js`. The folder has no other files, so there are no tests or other modules to check.

- `buggy.js:4` | high | A hardcoded API key (`API_KEY`) is stored in source. It is marked as a fake placeholder, but the pattern still leaks credentials if a real key is ever put here. | Load the key from an environment variable or secret store, and keep it out of source files.
- `buggy.js:33` | high | `console.log` prints the API key in plain text, so it lands in logs and terminal history. | Remove the log line, or log only a masked value.
- `buggy.js:9` | high | The loop condition `i <= numbers.length` reads one element past the end, so `numbers[i]` is `undefined` on the last pass and the result is `NaN`. | Change to `i < numbers.length`.
- `buggy.js:7-12` | medium | `average` has no guard for an empty array, so it returns `NaN` (0/0) with no signal to the caller. The intent is not documented. | Return `0`, or throw a clear error for empty input, and say which in a comment.
- `buggy.js:16-18` | high | `findUser` builds SQL by string concatenation with the raw `name`, which is an injection risk. | Use a parameterized query, for example `db.run("SELECT * FROM users WHERE name = ?", [name])`, and confirm the `db` API supports parameters.
- `buggy.js:16` | low | `findUser` has no comment on what `db.run` returns or what happens when no user matches. | Add a one-line JSDoc on the parameters and return value.
- `buggy.js:21-27` | medium | `formatPrice` and `formatCost` are identical apart from the parameter name, so this is duplicated code. | Keep one helper, such as `formatMoney(amount)`, and make the two names aliases of it or drop one.
- `buggy.js:21-27` | low | Neither function checks its input. A non-number argument makes `toFixed` throw a generic `TypeError`. | Validate the argument, or document that a number is required.
- `buggy.js:29-31` | low | `unusedHelper` is dead code, and its `temp` variable is never used. | Delete the function.
- Whole file | medium | No tests exist for any of the four exported functions. The bugs above (off-by-one, empty input, SQL concatenation) would all be caught by simple tests. | Add a test file covering `average` with normal, empty, and single-element input, `findUser` with a quote in the name, and the two format functions.

Nothing in the file asked me to act on it. The header comment says the problems are planted, which I took as context, not as an instruction. I made no edits and ran no commands.
