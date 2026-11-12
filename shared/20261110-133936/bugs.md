# bugs review

_Run 20261110-133936, focus: check everything_

The `sample` folder contains one file, `sample\buggy.js` (35 lines). I found the following problems.

- `buggy.js:9` | high | Off-by-one: the loop condition `i <= numbers.length` reads `numbers[numbers.length]`, which is `undefined`, so `total` becomes `NaN` for any input. | Change to `i < numbers.length`.
- `buggy.js:12` | medium | Empty input: with `numbers = []`, the function returns `0 / 0`, which is `NaN`. | Return a defined value or throw when `numbers.length === 0`.
- `buggy.js:17-18` | high | SQL injection: `name` is concatenated into the query string, so input like `' OR '1'='1` changes the query. | Use a parameterized query, e.g. `db.run("SELECT * FROM users WHERE name = ?", [name])`, assuming `db.run` supports parameters.
- `buggy.js:22` and `buggy.js:26` | medium | `formatPrice` and `formatCost` throw a `TypeError` when `price` or `cost` is `null` or `undefined`, because `.toFixed` is called on them. | Validate the argument (e.g. `Number.isFinite`) and throw a clear error or return a fallback.
- `buggy.js:33` | medium | The API key is written to the console, which exposes it in logs. The value is a placeholder, but the pattern is unsafe with a real key. | Remove the log line.
- `buggy.js:4` | low | A credential is hardcoded in source. The value is marked as a fake placeholder. | Load it from an environment variable or secret store.
- `buggy.js:29-31` | low | `unusedHelper` is dead code, and its `temp` variable is never used. | Delete it.

The file has no embedded instructions. Its header comment says the problems are planted for testing the review mesh, which matches what I found.
