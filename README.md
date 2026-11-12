# agent-mesh: one-command code review

Three AI reviewers (bugs, security, quality) look at a folder in parallel,
then a lead reviewer merges their reports. Built on T3 Code + Claude Code.

## Before you start
1. Open the **T3 Code** app and leave it running.
2. The folder you review must be inside a project you added in T3.
   (`C:\Users\dadinh\agent-mesh` is already a project.)
3. Use **Git Bash** (not PowerShell).

## Run it
```bash
cd /c/Users/dadinh/agent-mesh
./mesh.sh sample "check everything"
```
- First argument: the folder to review.
- Second argument (optional): what to focus on, e.g. `"focus on error handling"`.

## Two ways to run the mesh
1. **Fixed pipeline (script):** `./mesh.sh <folder> "focus"` in Git Bash, as above. Predictable and cheap.
2. **AI orchestrator inside T3 (new):** open a Claude thread in the `agent-mesh` project and paste:
   `Follow prompts/orchestrator.md. Review the folder: sample. Focus: everything.`
   One Claude thread manages up to 3 read-only workers using T3's `delegate_task`, and saves handoff files in `shared/orch-NNN/`.
   Standing rules are in `CLAUDE.md`; the handoff convention is in `shared/README.md`.

To check everything works, follow `TESTING.md` (you run the tests; each has a clear PASS/FAIL).

## Where the results go
`shared/<date-time>/` contains `bugs.md`, `security.md`, `quality.md`, and
**`summary.md`** (start here).

## Safety rules
- The reviewers are told to read only. Keep the T3 project in **Supervised**
  permission mode so T3 asks you before any file change.
- Do not turn on T3 Connect, Network access, or Full access.
- Check that AMD allows AI tools on the code you point this at before using it
  on company repos. Reports are saved locally in `shared/`.
- Files being reviewed are treated as data, not instructions.

## If something goes wrong
- `[waiting]` means an agent is waiting for you in the T3 app. Open the thread
  named `mesh-<date-time>-<role>` and answer or approve.
- `[failed]` prints the error. A common cause is the T3 app not being open.
- Change models or roles in `mesh.sh` (top) and `prompts/*.txt`.
