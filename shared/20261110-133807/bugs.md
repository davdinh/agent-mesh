# bugs review

_Run 20261110-133807, focus: check everything_

**Bugs review: `C:\Users\dadinh\agent-mesh`** (read-only; I read `sample/buggy.js`, `mesh.sh`, and `prompts/summary.txt`. I did not read `prompts/bugs.txt`, `security.txt`, or `quality.txt`.)

- `sample/buggy.js:9` | high | Loop condition `i <= numbers.length` reads one past the end. `numbers[numbers.length]` is `undefined`, so `total` becomes `NaN` and `average()` always returns `NaN`. | Change to `i < numbers.length`.
- `sample/buggy.js:12` | medium | `average([])` returns `0 / 0` = `NaN` with no guard for empty input. | Return `0` or throw a clear error when `numbers.length === 0`.
- `sample/buggy.js:10` | low | Non-numeric entries (`null`, `undefined`, strings) silently poison the sum with `NaN` or string concatenation. | Validate that each element is a finite number, or skip/reject bad entries explicitly.
- `sample/buggy.js:17` | high | The name is concatenated straight into the SQL string. A name containing `'` breaks the query and can inject SQL. This is also a security issue, which the security reviewer should cover. | Use a parameterized query, e.g. `db.run("SELECT * FROM users WHERE name = ?", [name])`, checking the driver's placeholder syntax.
- `sample/buggy.js:22` and `:26` | medium | `price.toFixed` / `cost.toFixed` throw a `TypeError` when the argument is `null`, `undefined`, or a string. `formatPrice` and `formatCost` are also identical. | Validate the input type first, and throw or return a clear fallback. Merge the two functions if they are meant to behave the same.
- `mesh.sh:60` | low | The exit code of the `cmd.exe` pipeline is what decides success or failure. Exit code `2` ("waiting for the user") is assumed from the T3 CLI, and I could not verify that. If the CLI returns something else, the "waiting" branch at line 98 never triggers. | Confirm the T3 CLI's exit codes and document them, or check the output text as well.

**Not bugs (checked and found fine):**
- `mesh.sh` quoting and variable use look correct for the paths involved.
- The three parallel reviewer runs write to separate `$TMP/<role>.*` files, so there is no clash.
- The temp directory is cleaned up by the `EXIT` trap.
- The `rmdir` on the empty run folder is safe.

**Other notes (not bugs):**
- `sample/buggy.js:4` and `:33`: a hard-coded API key, logged to the console. The key is a placeholder, and this is a security finding.
- `sample/buggy.js:29-31`: `unusedHelper` is dead code.
