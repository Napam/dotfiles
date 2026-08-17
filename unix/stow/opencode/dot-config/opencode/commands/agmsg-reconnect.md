---
description: Reconnect every agent on an agmsg team after an opencode restart, with no herdr layer. Sends each member a reconnect message and confirms their inbox watchers are streaming again.
---

Reconnect a team to agmsg after an opencode restart, without herdr. OpenCode
restarts kill the sentinel watchers (in-memory and process-scoped), so each
member needs to relaunch its inbox watcher. This flow assumes monitor-mode
delivery; members in `turn` or `off` mode have no watcher to relaunch.

$ARGUMENTS

## 1. Preflight

Confirm this session's identity:

```bash
bash ~/.agents/skills/agmsg/scripts/whoami.sh "$(pwd)" opencode
```

Note AGENT and TEAMS from the output. Confirm delivery mode is `monitor`:

```bash
bash ~/.agents/skills/agmsg/scripts/delivery.sh status opencode "$(pwd)"
```

If the mode is `turn` or `off`, there are no watchers to reconnect: say so,
tell the user to check inbox manually, and stop.

## 2. Reconnect yourself

This session is itself a team member. If no `agmsg inbox stream` watcher is
streaming here, launch one now with `sentinel_monitor` per the agmsg skill
("Ensure monitor is running first"). Then confirm it is actually streaming:
run `sentinel_list` and check the watcher appears before proceeding. A failed
launch leaves your own inbox dark while you claim everyone else is back up.

## 3. Enumerate the roster

```bash
bash ~/.agents/skills/agmsg/scripts/team.sh <team>
```

Read the member names. Skip your own AGENT. If `$ARGUMENTS` names specific
agents (space-separated), target only those. Team members may be offline; the
reconnect message still lands in their inbox for the next turn.

## 4. Broadcast reconnect

For each target member, send a reconnect message. The member loads the
`agmsg` skill itself, relaunches its watcher, and replies:

```bash
bash ~/.agents/skills/agmsg/scripts/send.sh <team> <agent> <member> "agmsg reconnect. Reply 'watcher live' when streaming."
```

Keep the message plain text: backticks and `$` get eaten by the shell.

## 5. Confirm and report

Watch your inbox stream for each member's `watcher live` reply, or poll
`history.sh` after a short delay. Retry once for silent members, then report:

- Members reconnected (watcher confirmed streaming)
- Members silent: offline, not in monitor mode, or still starting

Keep the report short.