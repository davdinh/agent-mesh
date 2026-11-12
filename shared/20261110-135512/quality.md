# quality review

_Run 20261110-135512, focus: check everything_

Reviewed the only file in `C:\Users\dadinh\agent-mesh\sample`: `sample\buggy.js`. It's a 36-line file, so no subagents were needed. The file's header says it contains planted problems, and I took that at face value.

**Findings**

- `buggy.js:9` | high | Off-by-one: `i <= numbers.length` reads `numbers[length]` (undefined), so `total` becomes NaN. An empty array also returns `0/0` = NaN, and nothing documents or guards that case. | Use `i < numbers.length`, and return a defined result or throw for empty input.
- `buggy.js:4` | high | Hardcoded API key in source. | Load it from the environment or a config file that is not committed.
- `buggy.js:33` | high | Module-level `console.log` prints the key on every `require`, a side effect in a library module. | Remove it.
- `buggy.js:17-18` | high | SQL built by string concatenation (injection risk), and `db.run` errors are not handled or documented. | Use a parameterized query and document the `db` contract and error behavior.
- `buggy.js:25-27` | medium | `formatCost` is an exact duplicate of `formatPrice` (lines 21-23). | Delete one, or make one call the other, and keep a single name.
- `buggy.js:29-31` | medium | `unusedHelper` is dead code, and its `temp` variable is unused. | Delete both.
- `buggy.js:21-27` | low | `formatPrice`/`formatCost` throw an unhelpful `TypeError` for non-numbers or `undefined`, and the two names don't say what they differ in. | Validate input, and add a comment stating the intended difference or merge them.
- `buggy.js:7`, `16` | low | No doc comments on expected input types or error behavior (empty array, `db` shape, what `findUser` returns). | Add short JSDoc blocks.
- Whole file | medium | No tests for any exported function (`average`, `findUser`, `formatPrice`, `formatCost`). That is why the off-by-one and duplicate helpers went unnoticed. | Add a small test file covering empty input, the last element, and a parameterized `findUser`.

The security items (hardcoded key, SQL concatenation, logged secret) are outside pure quality, but I listed them because they are high severity. Nothing in the file tried to give instructions. I did not edit or run anything.
