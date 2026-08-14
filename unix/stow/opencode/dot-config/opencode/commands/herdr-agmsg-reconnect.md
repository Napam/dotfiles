---
description: Reconnect every herdr pane agent to agmsg after an opencode restart. Enumerates live agents, prompts each to relaunch its inbox watcher, and reports results.
agent: herdr-controller
---

Reconnect all agents in this herdr session to agmsg. OpenCode restarts kill
the sentinel watchers (they are in-memory and process-scoped), so every pane
agent needs to relaunch its inbox watcher.

$ARGUMENTS

## 1. Preflight

Verify you are inside herdr:

```bash
test "${HERDR_ENV:-}" = 1
```

If the check fails, say you are not inside herdr and stop. Otherwise confirm
`herdr agent list` works before doing anything else.

## 2. Reconnect yourself

This session is itself a herdr pane agent. If no `agmsg inbox stream` watcher
is streaming here, launch one now with `sentinel_monitor` per the agmsg skill
("Ensure monitor is running first"). Then confirm it is actually streaming:
run `sentinel_list` and check the watcher appears before proceeding. A failed
launch leaves your own inbox dark while you claim everyone else is back up.
Note your own herdr agent name from `herdr agent list` (match the pane with
`$HERDR_PANE_ID`) so you skip yourself in the broadcast below.

## 3. Enumerate live agents

```bash
herdr agent list
```

Read the names from the JSON. Do not cache names from a previous run: a pane
agent that restarted gets re-detected and may be re-assigned a new name.

## 4. Broadcast reconnect

For each live agent that is not you, prompt it to reconnect. The agent loads
the `agmsg` skill itself; the prompt only names the action and the expected
reply:

```bash
herdr agent prompt <name> "agmsg reconnect. Reply 'watcher live' when streaming." --wait --timeout 60000
```

If `$ARGUMENTS` names specific agents (space-separated), prompt only those.

Tolerate failures: `agent_prompt_stalled` or a timeout can mean the pane
agent was mid-startup, is not a herdr-worker, or has no agmsg skill loaded.
Retry once after a short delay, then move on.

## 5. Re-enumerate and report

Run `herdr agent list` again to catch re-assigned names and confirm who is
reachable. Report:

- Agents reconnected (watcher confirmed streaming)
- Agents unreachable: not a worker, no skill loaded, or still starting
- Any agent names that changed

Keep the report short.
