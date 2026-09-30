---
name: subagent-ops
description: >
  Inspect and steer in-flight opencode subagents: native subagent tool first,
  the opencode CLI and API for the rest.
  Use when asked to check what a running subagent is doing, redirect one with
  new instructions, interrupt one, switch its agent or model, answer a child's
  question, collect results from parallel workers, or diagnose a stuck or failed
  child session. Triggers on "check on the subagent", "what is it doing",
  "redirect the subagent", "interrupt the subagent", "in-flight subagent".
---

Manipulation of running subagents only. Spawning and delegation are covered by
opencode itself. This skill starts after launch.

Prefer the `subagent` tool's own mechanics: it continues (steers) a session by
`sessionID`, and both `agent` and `model` can switch mid-session. The
API covers what no tool exposes: inspection, forms, interrupt, compact.
Session deletion is the `opencode session delete` CLI.

All API calls go through `opencode api METHOD /path`. Auth is handled. Raw curl
gets 401. Replace `$S` with the child session ID, `$P` with the parent ID.

WARN: touch only sessions you own. Before prompting, interrupting, or deleting,
ensure `.data.parentID` equals your session. Other running agents and
subagents belong to someone else. Leave them alone.

## Find the child ID

The `subagent` tool returns the child ID at launch in background mode; a
foreground call returns it only with the report. Keep it. If lost:

```sh
opencode api GET "/api/session?parentID=$P" | jq -r '.data[] | [.id, .agent, .title] | @tsv'
opencode api GET /api/session/active | jq -r '.data | keys[]'  # executing only; idle ones absent
```

`opencode session list` shows roots. The API list without a filter returns
roots and children. Filter with `?parentID=$P`.

## Inspect state

```sh
opencode api GET "/api/session/$S" | jq '.data | {agent, model, tokens, cost, updated: .time.updated}'
opencode api GET "/api/session/$S/message" | jq -r '.data[] | "\(.type) [\(.agent // "-")]"'
```

WARN: a response past ~192KB breaks a direct pipe into jq. Redirect to a temp
file first, or page with `?limit=N`.

`message.list` is newest-first. A running tool call shows
`state.status: "running"` with its input. `.data.time.updated` barely moves
while a tool runs. Read it twice while `state.status == "running"` and compare.
Confirm liveness against the process table, matching the command string from
the tool input:

```sh
ps -o pid,etime,command -ax | grep "<distinctive-command-substring>" | grep -v grep
```

Use `ps` as a last resort. It matches the host, not the session. Grepping the
session directory does not work. The working directory is not in `ps` output.

## Steer a running session

Re-invoke the `subagent` tool with the child's `sessionID` and the new
instructions as the prompt. That is the steer itself; no API call needed. Pass
`background: true` to steer without blocking; the default waits for that run
and returns its report. If you lack tool access to that session (e.g. driving
it from shell rather than the harness), post the prompt over the API instead:

```sh
opencode api POST "/api/session/$S/prompt" -d '{"text":"New instructions."}' | jq -r '.data.delivery'
```

Both routes land as steering input: they do not interrupt a running tool, they
run at the next step boundary. Observed live with the tool route: a steer
landed mid-task and the worker dropped its in-flight work at the next step.
The API response's `.data.delivery` reports `steer`; pass
`-d '{"text":"...","delivery":"queue"}'` to wait behind queued prompts
instead. Allow ~10s for the model to react, then poll `message.list` until the
newest message changes or the newest assistant message gains a tool call.

For re-delegation content, paste a short continuation block, not the full prior
hand-off:

```
## Continuation Context
- Already done: [subagent's last report summary]
- New instruction: [what this run does]
- Corrections: [overrides to prior context]
```

Do not steer a worker around its constraints. If it reports a conflict or
failure it did not cause, leave it alone and escalate instead of redirecting
around the problem.

## Answer a child's question

Checked with `debug agents`: `general` and `min` have `question * deny` and
cannot ask questions. `build` has `question * allow`. Agents with no
`question` rule are untested. An asked question appears as a form, not in
messages. List first for the form ID and field keys:

```sh
opencode api GET "/api/session/$S/form" | jq '.data[] | {id, title, fields}'
opencode api POST "/api/session/$S/form/<formID>/reply" -d '{"answer":{"q0":"Blue"}}'
```

Reply returns empty on success. Re-list forms to confirm it settled. The agent
resumes on its own. Poll `message.list` for the follow-up.

## Switch agent or model mid-run

Re-invoke the `subagent` tool with the child's `sessionID` and a new `model` or
`agent` param. Verified live for both: the session logs a `model-switched`
message, the following turn runs on the new model, and `.data.agent` flips.

A pure switch with no new instructions needs the API. Both calls return 204 and
nothing runs until the next turn, so no spend happens at switch time:

```sh
opencode api POST "/api/session/$S/agent" -d '{"agent":"explore"}'
opencode api POST "/api/session/$S/model" -d '{"model":{"providerID":"opencode-go","id":"glm-5.3-flash"}}'
```

Confirm model IDs with `opencode models` first. IDs go stale.

## Interrupt

```sh
opencode api POST "/api/session/$S/interrupt"
```

Returns `{"interrupted":true}`. Kills the running process. The tool call is
marked `status: "error"`. The session stays alive and accepts new prompts. Per
the spec, `?resume=true` resumes pending steering input and next-in-line
control items while queued prompts stay parked. In one live test it showed no
visible difference from a plain interrupt.

WARN: interrupting a session launched via the `subagent` tool cancels its
background tracking (observed: the background job reports cancelled). Do not
expect a notification for the cancelled job. A re-invoke with its `sessionID`
starts a fresh run and works (verified live); use the API prompt route only
when the tool is not usable to you.

## Collect results

The foreground return or the background notification carries the report. Read
the `STATUS:` line first. Coding subagents close reports with `STATUS:
done`, `partial`, or `blocked`, and a missing line means partial. That is a
prompt convention, not API behavior. For detail beyond the report, the newest
message is not always an assistant message, so filter:

```sh
opencode api GET "/api/session/$S/message" | jq '[.data[] | select(.type=="assistant")] | first'
opencode api GET "/api/experimental/session/$S/export" | jq '.data.info | {cost, tokens, outcome}'
```

`GET /api/session/$S/context` returns post-compaction messages only. For full
history, page `message.list`.

## Compact a long-running child

```sh
opencode api POST "/api/session/$S/compact" -d '{}'
```

Returns 200 with `{"data": ...}`. Wait for the run to finish (foreground return
or background notification), then read the `compaction` message for its
`summary`, `status`, and `reason`. Old messages stay listed but context is now
the summary.

## Failure gotchas

A `kill -9` on the child process looks like success: tool `status:
"completed"` with empty output, and the agent may rationalize it. Reproduced
live. Treat empty tool output as suspect. Re-check with an independent command.

## Cleanup

```sh
opencode session delete "$S"
```

Delete removes the session and its child sessions. `opencode api DELETE
"/api/session/$S"` does the same when the CLI is not available.
