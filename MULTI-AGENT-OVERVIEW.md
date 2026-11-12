# Multi-Agent Code Review Mesh: Overview

A small, layered **multi-agent system** that reviews a code folder with several specialist AI agents working in parallel, then merges their findings. It runs inside [T3 Code](https://github.com/pingdotgg/t3code) (an open-source control surface for coding agents) using Claude as the agent provider.

This document explains **how it is built, why it is robust, and what is and is not proven yet**.

---

## 1. The idea in one picture

One **orchestrator** breaks the job up, several **read-only workers** each look at the code from a different angle, and the results are saved as files that any later session can read.

```mermaid
flowchart LR
    U["User"] --> O["Orchestrator<br/>(one AI thread in T3 Code)"]
    O -->|"delegate_task"| W1["Worker: bugs<br/>(read-only)"]
    O -->|"delegate_task"| W2["Worker: security<br/>(read-only)"]
    O -->|"delegate_task"| W3["Worker: quality<br/>(read-only)"]
    W1 -->|"report"| O
    W2 -->|"report"| O
    W3 -->|"report"| O
    O -->|"writes"| S[("shared/run-id/<br/>brief, reports,<br/>summary, log")]
    S -.->|"read by next session"| O
    O --> R["Short answer to user<br/>+ path to summary"]
```

### Roles
| Role | Count | Job | Can it change files? |
|---|---|---|---|
| Orchestrator | 1 | Plan, start workers, collect results, write the summary and log | Only inside `shared/` |
| Worker: bugs | 1 | Logic errors, crashes, edge cases | No (read-only) |
| Worker: security | 1 | Secrets, injection, unsafe input | No (read-only) |
| Worker: quality | 1 | Duplication, dead code, missing tests | No (read-only) |

A **fixed-pipeline fallback** (`mesh.sh`) does the same job with a plain script as the coordinator and one extra "lead" agent for the summary. It is predictable and cheap, and it stays available if the AI orchestrator misbehaves.

---

## 2. What happens in one run

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Orch as Orchestrator
    participant Bugs as Worker bugs
    participant Sec as Worker security
    participant Qual as Worker quality
    participant Files as shared folder

    User->>Orch: Review folder X, focus Y
    Orch->>Orch: Read standing instructions and handoff rules
    Orch->>Orch: Check folder X exists and is readable
    Orch->>Files: Write brief.md (goal, workers, done condition)
    par Start workers in parallel
        Orch->>Bugs: Task = role + rules + scope
        Orch->>Sec: Task = role + rules + scope
        Orch->>Qual: Task = role + rules + scope
    end
    Bugs-->>Orch: Full report
    Sec-->>Orch: Full report
    Qual-->>Orch: Full report
    Orch->>Files: Save each report
    Orch->>Files: Write summary.md (merged and prioritized)
    Orch->>Files: Write log.md (timeline, failures, refusals)
    Orch-->>User: Verdict, top issues, path to summary
```

---

## 3. Why it is robust

Robustness here comes from **several independent safety layers**, so no single mistake or bad prompt can cause damage on its own.

```mermaid
flowchart TB
    A["Layer 1: Scope<br/>Workers only see one named folder"] --> B["Layer 2: Read-only by instruction<br/>Worker contract forbids edits and commands"]
    B --> C["Layer 3: Read-only by permission<br/>Workers started in Supervised mode, so T3 asks before any change"]
    C --> D["Layer 4: Write boundary<br/>Only the orchestrator writes, and only inside shared/"]
    D --> E["Layer 5: Data, not orders<br/>Reviewed files and reports are treated as data, never instructions"]
    E --> F["Layer 6: No secrets in output<br/>Secrets are shortened to 4 characters"]
    F --> G["Layer 7: Human in the loop<br/>Findings are advice to review, not automatic changes"]
```

### Failure handling: nothing is silently skipped
A worker that fails, times out, is interrupted or returns nothing is **recorded as a failure**, never reported as "no issues found".

```mermaid
flowchart TD
    S["Start a worker"] --> Q{"Finished with<br/>status completed?"}
    Q -->|"Yes"| R{"Reply has<br/>content?"}
    Q -->|"No: failed, timed out,<br/>interrupted, waiting"| F["Mark FAILED or INCOMPLETE"]
    R -->|"Yes"| OK["Save report"]
    R -->|"No: empty"| F
    F --> L["Write reason to log.md"]
    L --> M["Say so explicitly in summary.md"]
    OK --> M2["Include in summary.md"]
    M --> D["Continue with remaining workers"]
    M2 --> D
```

Other guard rails:
- **Capped fan-out:** at most 3 workers, and workers cannot start workers.
- **Input checks:** if the target folder cannot be read, the run stops, logs why, and does not guess another folder.
- **Idempotent task names:** each worker has a unique request id, so a retry cannot create duplicates.
- **Refuses scope creep:** if asked to "also fix the bugs", the orchestrator stops and asks first.

---

## 4. Memory: how agents "don't lose" information

Agents do not remember anything between conversations. The system treats memory as **layers of written notes**.

```mermaid
flowchart LR
    subgraph Short["Short-term"]
        W["Working memory<br/>one thread's conversation"]
    end
    subgraph Durable["Durable (survives sessions)"]
        H["Thread history<br/>saved by T3 Code"]
        I["Standing instructions<br/>CLAUDE.md, read every session"]
        N["Handoff files<br/>shared/run-id/"]
    end
    W -->|"too long: summarized"| W
    W -->|"orchestrator writes"| N
    I -->|"loaded at start"| W
    N -->|"read by next session"| W
    H -->|"resume"| W
```

Key rule: **a delegated worker starts with no memory of the parent**, so everything it needs is passed in its task text, and everything that must last is written to `shared/`.

Handoff folder layout for one run:

```mermaid
flowchart TD
    R["shared/orch-001/"] --> B["brief.md<br/>what was asked and why"]
    R --> W1["bugs.md"]
    R --> W2["security.md"]
    R --> W3["quality.md"]
    R --> S["summary.md<br/>start here"]
    R --> L["log.md<br/>timeline, failures, refusals"]
```

---

## 5. Two ways to run it, side by side

| | Fixed pipeline (`mesh.sh`) | AI orchestrator in T3 |
|---|---|---|
| Coordinator | A bash script (fixed steps) | A Claude thread (decides) |
| Can skip a worker when not relevant | No | Yes, and must say why |
| Predictability | Very high | Medium |
| Cost per run | About 4 short threads | About 4 short threads |
| Visible in the T3 sidebar | Yes (threads) | Yes (parent plus children) |
| Best for | "Run the same review every time" | "Look at this and decide what is needed" |

---

## 6. Evidence: what is proven and what is not (honest status)

Robustness claims should be backed by tests. Status as of this writing:

| Check | Status |
|---|---|
| Script run on a sample file with planted problems finds the SQL injection, an off-by-one loop and a hard-coded key | **Verified** (3 successful runs) |
| Reviewers stay inside the requested folder | **Verified** after a scope bug was found and fixed on the second run |
| Sample file is never modified by a review | **Verified** (size and timestamp unchanged) |
| Full fake secret never appears in reports | **Verified** (search found none) |
| Bad input fails cleanly (no folder, missing folder) | **Verified** |
| First run failed because of a quoting bug; no agents started and nothing was spent | **Found and fixed** |
| AI orchestrator starts 3 parallel workers and writes all handoff files | **Not yet tested** (test T2) |
| Orchestrator refuses to edit code outside `shared/` | **Not yet tested** (test T3) |
| Failed or interrupted worker is reported as a failure, not as "clean" | **Not yet tested** (test T4) |
| A brand-new session can resume from handoff files alone | **Not yet tested** (test T5) |

The tests are written as plain PASS/FAIL steps in `TESTING.md`.

```mermaid
flowchart LR
    T0["T0 Preflight"] --> T1["T1 Script still works"]
    T1 --> T2["T2 Orchestrator happy path"]
    T2 --> T3["T3 Edit boundary"]
    T3 --> T4["T4 Failure handling"]
    T4 --> T5["T5 Memory and handoff"]
    T5 --> T6["T6 Cost check"]
    style T0 fill:#fff3cd,stroke:#b58900
    style T1 fill:#d4edda,stroke:#2e7d32
    style T2 fill:#fff3cd,stroke:#b58900
    style T3 fill:#fff3cd,stroke:#b58900
    style T4 fill:#fff3cd,stroke:#b58900
    style T5 fill:#fff3cd,stroke:#b58900
    style T6 fill:#fff3cd,stroke:#b58900
```

Green means verified, yellow means not yet run.

---

## 7. Known limits (stated plainly)

- **Instructions are not a sandbox.** Read-only behavior is enforced by T3's Supervised mode for workers and by written rules. A permissive project setting (such as Auto-accept edits) weakens it, so that mode is only used on this one project, with writes limited to `shared/`.
- **AI reviewers can be wrong.** They can miss issues or report false alarms. Treat findings as input for a human, not a verdict.
- **Orchestration in T3 Code is new** (shipped in October 2026), so expect rough edges.
- **Cost scales with agents.** Each extra parallel worker adds roughly one more thread of usage, which is why fan-out is capped at 3.
- **Confidential code:** reviewed text is sent to the model provider. Only run it on code you are allowed to share with that provider.

---

## 8. Roadmap (not built yet)

```mermaid
flowchart LR
    N["Now<br/>Read-only review<br/>1 orchestrator + 3 workers"] --> A["Next<br/>Workers that edit code<br/>in separate git worktrees<br/>with one merge owner"]
    A --> B["Then<br/>Scheduled recurring reviews"]
    B --> C["Later<br/>More roles: tests, docs<br/>Long-term memory vault"]
```

---

## 9. Files in this project

| File | Purpose |
|---|---|
| `CLAUDE.md` | Standing instructions every session reads |
| `prompts/orchestrator.md` | The orchestrator's step-by-step playbook |
| `prompts/bugs.txt`, `security.txt`, `quality.txt` | The three worker roles |
| `prompts/worker-contract.md` | Rules every worker must follow |
| `prompts/summary.txt` | Instructions for the fixed pipeline's lead agent |
| `shared/README.md` | The handoff (memory) convention |
| `mesh.sh` | Fixed-pipeline runner (bash) |
| `sample/buggy.js` | A test file with planted problems and a made-up key |
| `TESTING.md` | Plain PASS/FAIL tests |
