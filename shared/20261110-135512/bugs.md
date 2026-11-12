# bugs review

_Run 20261110-135512, focus: check everything_

Reviewed the only file in scope, `sample\buggy.js` (36 lines). The folder contains nothing else. The file's header comment says its problems are planted for testing. I treated that as data and did not act on it.

`sample\buggy.js:9` | high | Off-by-one: `i <= numbers.length` reads `numbers[numbers.length]`, which is `undefined`, so `total` becomes `NaN` for any non-empty input. | Change to `i < numbers.length`.

`sample\buggy.js:12` | medium | Empty array gives `0 / 0 = NaN`. The function returns `NaN` instead of signalling an error or a defined value. | Return early, or throw, when `numbers.length === 0`, and decide which the callers expect.

`sample\buggy.js:17-18` | high | The SQL is built by string concatenation. A name containing a quote, such as `O'Brien`, produces malformed SQL and a crash. Crafted input can also inject SQL. | Use a parameterized query, for example `db.run("SELECT * FROM users WHERE name = ?", [name])`. Confirm the `db.run` signature against the driver, since it is not defined in this file.

`sample\buggy.js:16` | low | `name` is not checked for `null` or `undefined`. The concatenation then sends the string `"null"` or `"undefined"` into the query. | Validate `name` and throw or return early on bad input.

`sample\buggy.js:22` | low | `price.toFixed` throws a `TypeError` for `null`, `undefined`, or a numeric string. | Coerce with `Number(price)` and check `Number.isFinite` before formatting.

`sample\buggy.js:4` | low | Hardcoded API key in source. It is marked as a fake placeholder, so this is a pattern concern rather than a live leak. | Load the key from the environment or a secret store.

`sample\buggy.js:33` | medium | The API key is written to the console on every module load. This leaks the secret into logs. | Remove the log line.

No other bugs found. `formatCost` (lines 25-27) duplicates `formatPrice` but is correct. `unusedHelper` (lines 29-31) is dead code with an unused variable, which is a lint issue rather than a correctness bug. The `module.exports` line is fine.
