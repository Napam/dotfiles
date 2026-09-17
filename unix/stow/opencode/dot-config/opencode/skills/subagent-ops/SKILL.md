---
name: subagent-ops
description: >
  Inspect and steer in-flight opencode2 subagents via the opencode2 CLI and API.
  Use when asked to check what a running subagent is doing, redirect one with
  new instructions, interrupt one, switch its agent or model, answer a child's
  question, collect results from parallel workers, or diagnose a stuck or failed
  child session. Triggers on "check on the subagent", "what is it doing",
  "redirect the subagent", "interrupt the subagent", "in-flight subagent".
---

Manipulation of running subagents only. Spawning and delegation are covered by
opencode2 itself. This skill starts after launch.

All calls go through `opencode2 api METHOD /path`. Auth is handled. Raw curl
gets 401. Replace `$S` with the child session ID, `$P` with the parent ID.

WARN: touch only sessions you own. Before prompting, interrupting, or deleting,
esnure `.data.parentID` equals your session. Other running agents and
subagents belong to someone else. Leave them alone.

## Find the child ID

The `subagent` tool returns the child ID at launch. Keep it. If lost:

```sh
opencode2 api GET "/api/session?parentID=$P" | jq -r '.data[] | [.id, .agent, .title] | @tsv'
opencode2 api GET /api/session/active | jq -r '.data | keys[]'  # live sessions only
```

`opencode2 session list` shows roots. The API list without a filter returns
roots and children. Filter with `?parentID=$P`.

## Inspect state

```sh
opencode2 api GET "/api/session/$S" | jq '.data | {agent, model, tokens, cost}'
opencode2 api GET "/api/session/$S/message" | jq -r '.data[] | "\(.type) [\(.agent // "-")]"'
```

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

```sh
opencode2 api POST "/api/session/$S/prompt" -d '{"text":"New instructions."}' | jq -r '.data.delivery'
```

A prompt sent while a tool runs does not interrupt it. It queues behind the
current tool and runs after. Poll `message.list` until a new assistant or tool
entry appears. Allow ~10s for the model to react.

For re-delegation content, paste a short continuation block, not the full prior
hand-off:

```
## Continuation Context
- Already done: [subagent's last report summary]
- New instruction: [what this run does]
- Corrections: [overrides to prior context]
```

Do not steer a worker that was told to stay in its paths. If it reports a
conflict or failure it did not cause, leave it alone and escalate instead of
redirecting around the problem.

## Answer a child's question

Checked with `debug agents`: `general` and `min` have `question * deny` and
cannot ask questions. `build` has `question * allow`. Agents with no
`question` rule are untested. An asked question appears as a form, not in
messages. List first for the form ID and field keys:

```sh
opencode2 api GET "/api/session/$S/form" | jq '.data[] | {id, title, fields}'
opencode2 api POST "/api/session/$S/form/<formID>/reply" -d '{"answer":{"q0":"Blue"}}'
```

Reply returns empty on success. Re-list forms to confirm it settled. The agent
resumes on its own. Poll `message.list` for the follow-up.

## Switch agent or model mid-run

Both return 204. Nothing runs until the next turn, so no spend happens at
switch time:

```sh
opencode2 api POST "/api/session/$S/agent" -d '{"agent":"explore"}'
opencode2 api POST "/api/session/$S/model" -d '{"model":{"providerID":"opencode-go","id":"glm-5.3-flash"}}'
```

Confirm model IDs with `opencode2 models` first. IDs go stale.

## Interrupt

```sh
opencode2 api POST "/api/session/$S/interrupt"
```

Returns `{"interrupted":true}`. Kills the running process. The tool call is
marked `status: "error"`. The session stays alive and accepts new prompts. Per
the spec, `?resume=true` resumes pending steering input and next-in-line
control items while queued prompts stay parked. In one live test it showed no
visible difference from a plain interrupt.

WARN: interrupting a session launched via the `subagent` tool drops the
harness background tracking for it (observed: the background job reports
cancelled). Drive it by API after that. Do not expect the normal background
notification.

## Collect results

Read the `STATUS:` line first. Coding subagents close reports with `STATUS:
done`, `partial`, or `blocked`, and a missing line means partial. That is a
prompt convention, not API behavior. Then pull detail. The newest message is
not always an assistant message, so filter:

```sh
opencode2 api GET "/api/session/$S/message" | jq '[.data[] | select(.type=="assistant")] | first'
opencode2 api GET "/api/experimental/session/$S/export" | jq '.data.info | {cost, tokens, outcome}'
```

`GET /api/session/$S/context` returns post-compaction messages only. For full
history, page `message.list`.

## Compact a long-running child

```sh
opencode2 api POST "/api/session/$S/compact" -d '{}'
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
opencode2 api DELETE "/api/session/$S"
```

Delete removes the session and its child sessions.
