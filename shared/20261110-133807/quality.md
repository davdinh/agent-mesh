# quality review

_Run 20261110-133807, focus: check everything_

Quality review of `C:\Users\dadinh\agent-mesh`. I read all six files (`mesh.sh`, `sample/buggy.js`, and the four `prompts/*.txt`) and ran no commands. The prompt files contained no instructions aimed at me.

**sample/buggy.js**

- `sample/buggy.js:21` | medium | `formatPrice` and `formatCost` (lines 21-27) are identical copies. | Keep one helper and have the other call it, or delete the duplicate and update callers.
- `sample/buggy.js:7` | medium | `average` has no empty-array guard, so `[]` returns `NaN`, and the `<=` loop bound reads past the end (the bugs reviewer will also flag this). Its return contract is undocumented. | Return or throw explicitly for empty input, change `<=` to `<`, and add a one-line comment on the contract.
- `sample/buggy.js:16` | medium | `findUser` builds SQL by string concatenation with no error handling. The name `findUser` and the call `db.run` don't say whether rows come back. | Use a parameterized query with the read method that returns rows (for example `all`/`get`, depending on the driver), and document or handle errors. The security reviewer will flag the injection.
- `sample/buggy.js:33` | medium | A module-level `console.log` runs on every `require` and prints the key. That is a side effect on import. | Remove it.
- `sample/buggy.js:4` | low | The key is hardcoded in source (shown here as `sk-F...`). The security reviewer owns this. | Read it from the environment.
- `sample/buggy.js:29` | low | `unusedHelper` and its `temp` variable are dead code. | Delete them.
- `sample/buggy.js:22` | low | `price.toFixed` and `cost.toFixed` throw an unclear `TypeError` on non-numbers, with no validation. | Validate with `Number.isFinite` or document the expected input type.

**mesh.sh**

- `mesh.sh:11` | medium | The header says the agents "are read-only", but nothing enforces it. The only guard is prompt text, and `thread start` (line 60) passes no restrictive runtime mode. | Pass a restrictive mode if the CLI supports one, or reword the comment to say the agents are instructed to be read-only.
- `mesh.sh:55` | medium | The header documents exit code 2 as "waiting for an answer", but nothing checks for it. The code relies on an unverified CLI exit-code convention. | Confirm the CLI's exit codes and cite them in a comment, or detect the waiting state explicitly.
- `mesh.sh:60,63` | medium | stderr is merged into stdout (`2>&1`), so CLI warnings can land in the saved report. `sed '1{/^Thread /d}'` strips the first line by matching the CLI's output format. | Keep stdout and stderr separate, and comment the format assumption.
- `mesh.sh:19` | low | The T3 path is hardcoded to one user's profile, and the model IDs are fixed. | Allow overrides, for example `T3="${T3:-...}"`.
- `mesh.sh:33` | low | `cygpath` is required (Git Bash only), and that dependency is undocumented. | Note it in the header, or check `command -v cygpath` with a clear message.
- `mesh.sh:81,118` and `mesh.sh:84-90,119-125` | low | The exit-code reading and the report-file writing are each duplicated. | Extract `read_rc` and `write_report <file> <title>` helpers.

**prompts/ and project**

- `prompts/bugs.txt:5-11`, `security.txt:5-11`, `quality.txt:5-11` | low | The same rules block is copied three times, so the copies can drift. | Move the shared rules into one file and concatenate it in `mesh.sh`.
- Project root | low | No tests exist for `average`, `findUser`, the format functions, or `mesh.sh`. There is no README and no `.gitignore` for the `shared/` output folder. The folder is not a git repo. | Add a small test file (for example with `node:test`), a README with usage, and a `.gitignore` entry for `shared/`.

Nothing in the code is a clear dead path or an overly long function. The project is small, so no long-function findings apply.
