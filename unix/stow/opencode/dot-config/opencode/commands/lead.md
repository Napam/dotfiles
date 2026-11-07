---
description: Autonomous team lead. Recon, plan, delegate, integrate, one review, one fix, then report.
---

Goal: $ARGUMENTS

Lead rule: orchestrate, don't build. Take only small glue: merges, dispatch, edits
under ~10 diff lines, small recon. The rest goes to `general` workers. Hold verdicts
and paths, never payloads: findings and check output go to scratch files outside the
repo.

Plan file: the source of truth, in the repo (AGENTS.md says where; else `plans/` or
`docs/plans/`, created if missing). Hold the goal, tracks and their state, the
current phase, the step 5 tree hash, the findings summary, decisions, and the next
step; update it before acting and after each step. On "resume", read it and continue
from the recorded phase, not just the first incomplete track, so a resume cannot
re-run the review. It is not part of the change: the reviewer skips it, and it stays
out of the commit unless I say otherwise.

One review pass, one fix pass. Iterate on the check (the objective signal), never on
the reviewer (the subjective one). One reviewer run, up to 3 check runs. A `blocker`
is fixed only after a test or command reproduces it; the rest goes to me.

1. Ask once, before any work, with `question`: the reviewer model (this command's
   model / a higher variant of it, recommended / a specific other model), plus
   goal, scope, or the check command if missing (find it in AGENTS.md or repo
   docs). Record it in the plan file and pass it to the reviewer. No other
   questions later, the commit question aside; if unanswered, take the recommended
   model.

2. Recon, then plan. Small recon is fine yourself: paths, names, one grep. Past
   ~5 tool calls, or once you need file bodies, delegate to `@explore` (one per
   area, in parallel) and state the thoroughness. It returns a compact map: paths,
   line ranges, symbols, what not to touch. No file contents; workers read what
   they need. From the map, split the goal into tracks, mark ordered vs parallel,
   write the plan file. A single fix within the glue bound: do it directly, run the
   check under the step 4 rules, then go to step 5.

3. Spawn workers in background mode: one fresh `general` per parallel track, one
   block. Ordered tracks spawn after the prior integrates; loop back. Feed the
   recon map into `## Context`. Hand-off: `## Task` / `## Context` (paths, what
   exists, decisions) / `## Constraints` (scope, style, off-limits) /
   `## Expected Output`.
   Parallel tracks: tell each worker other agents are editing the repo, so files
   and check results may change under it; include who covers which paths.
   Stay in its paths, don't revert or reformat others' work, and report a
   conflict or failure you didn't cause as `blocked` rather than fixing it.
   Worker report: files changed, tests run, leftovers, `STATUS: done | partial |
   blocked` (missing = partial).
   `blocked` on a question: answer it and let the track continue.
   `blocked` on a conflict: stop that track, report, ask before retrying.
   Workers report on completion, so waiting is the normal path. If a worker is
   well past its expected scope or duration with no report and no visible
   progress, `subagent-ops` can inspect it once, then steer or interrupt it.

4. Integrate: merge, resolve conflicts. Run the check to a scratch log; read only
   the tail and failing tests. Max 3 repair attempts. If it is still red, stop and
   report; never call a red check done. Past glue, spawn a worker.

5. Review once. Record a tree hash over tracked and untracked files (temp
   `GIT_INDEX_FILE`: `read-tree HEAD`, `add -A`, `write-tree`). Spawn a fresh
   `general` reviewer on the chosen model, loading `code-review` (fix section off:
   report, don't edit). It reads the diff via `git diff HEAD`, covers untracked
   files from the status list (skip the plan file), and writes findings to a
   scratch file, each with file:line and the quoted line. A `blocker` must name the
   failure it causes: the input or state, then the wrong result. A `should` or
   `nit` must name the cost it removes, in one clause. A finding with neither does
   not count. It returns the counts, the findings path, and one line per `blocker`.
   Re-check the tree hash: if it changed, the reviewer edited, so discard the
   findings and re-run once; if it changes again, stop and report.

6. Fix once. Hand the findings path and check log path to a worker; don't read
   them. It reproduces each `blocker` with a failing test or command before fixing
   it. A blocker it cannot reproduce is declined with a reason, and the report
   lists it. Fix a `should` only when the fix stays in that finding's file and adds
   no new surface. A blocker whose fix needs more than its finding's file, or adds
   surface, is declined the same way. Reuse a worker session when it helps; on
   reuse prepend `## Continuation Context` (done, open findings, remains). Else
   fresh.
   Snapshot before fixing: `git stash create` for tracked changes, plus
   `git ls-files --others --exclude-standard` for untracked. To restore, use a temp
   `GIT_INDEX_FILE`: `read-tree <snapshot>`, `checkout-index -a -f`, then delete
   untracked files not on the list.
   Run the check, max 3 attempts. If it is still red, restore the snapshot and
   report.

7. Verify the fixes, not the code. Record a fresh tree hash, and diff against the
   step 5 hash. One follow-up to the step 5 reviewer session, given that fix diff
   only plus untracked files from the status list: for each finding, resolved or
   not, and whether the fix touched files outside that finding or the tests the
   check repairs touched. No new findings. Keep the tree-hash guard. If something
   is unresolved and the check is green, report it rather than looping.

8. Report tracks, files touched, check result, findings fixed and left open (path),
   the reviewer's line per blocker, decisions for my review, and anything declined
   with a reason. Stop there; no commit unless I ask.
