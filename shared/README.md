# shared/ : the handoff folder (the mesh's memory)

Agents don't remember anything between threads. Anything that must outlive a conversation is written here, and the next agent is told to read it.

## Layout
One folder per run:
```
shared/
  orch-001/            <- run made by the T3 orchestrator (numbered 001, 002, ...)
    brief.md           what was asked, which workers, why, and the "done" condition
    bugs.md            the bugs worker's full report
    security.md        the security worker's full report
    quality.md         the quality worker's full report
    summary.md         the merged, prioritized summary (start here)
    log.md             timeline: workers, task ids, failures, anything skipped or refused
  20261110-135512/     <- run made by ./mesh.sh (date-time name): bugs/security/quality/summary only
```

## How a new session picks up where the last one stopped
1. Find the newest run folder.
2. Read its `summary.md`, then `log.md` (to see what failed or was skipped).
3. Read `brief.md` only if you need the original goal.
4. Say what you are relying on, so the user can check it.

## Rules
- Only the orchestrator writes here. Workers return their reports in their replies.
- Never put full secrets here (first 4 characters then `...`).
- Old runs are history, not truth. Code may have changed since. Check before acting on a finding.
- These reports may describe confidential code. Keep this folder local.
