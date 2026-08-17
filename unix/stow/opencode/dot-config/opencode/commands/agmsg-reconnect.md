---
description: Reconnect this session to agmsg after an opencode restart, no herdr layer. Relaunches this session's inbox watcher. Optionally broadcasts reconnect to named team members. Run manually in any team member.
---

Reconnect this session to agmsg after an opencode restart, without herdr.
OpenCode restarts kill the sentinel watchers (in-memory and process-scoped),
so each session needs to relaunch its inbox watcher. This flow assumes
monitor-mode delivery. Run this in every team member; pass agent names to
also broadcast reconnect to them.

$ARGUMENTS

## 1. Preflight

Confirm this session's identity:

```bash
bash ~/.agents/skills/agmsg/scripts/whoami.sh "$(pwd)" opencode
```

Note AGENT and TEAMS from the output. If whoami reports `not_joined`, stop
and say this session is not a team member; join first (`join.sh`) before
reconnecting. Confirm delivery mode is `monitor`:

```bash
bash ~/.agents/skills/agmsg/scripts/delivery.sh status opencode "$(pwd)"
```

If the mode is `turn` or `off`, there are no watchers to reconnect: say so
and stop. `turn` mode still self-checks each turn; `off` mode needs manual
checks.

## 2. Reconnect yourself

This session is itself a team member. If no `agmsg inbox stream` watcher is
streaming here, launch one now with `sentinel_monitor` per the agmsg skill
("Ensure monitor is running first"). If `sentinel_monitor` is unavailable,
fall back to `check-inbox.sh` after each tool call instead. Then confirm it
is actually streaming: run `sentinel_list` and check the watcher appears
before proceeding. A failed launch leaves your own inbox dark while you claim
everyone else is back up.

## 3. Broadcast (only with $ARGUMENTS)

Running this command reconnects this session. It does not broadcast to
others unless you name targets in $ARGUMENTS. That keeps the command safe to
run manually in every member: each one just reconnects itself, no cross-talk.

If $ARGUMENTS names specific agents (space-separated), send each a reconnect
message. Skip your own name if present. The member loads the `agmsg` skill
itself, relaunches its watcher, and replies:

```bash
bash ~/.agents/skills/agmsg/scripts/send.sh <team> <agent> <member> "agmsg reconnect. Reply 'watcher live' when streaming."
```

Keep the message plain text: backticks and `$` get eaten by the shell.
Team members may be offline; the reconnect message still lands in their inbox
for the next turn.

## 4. Confirm and report

If you broadcast, watch your inbox stream for each target's `watcher live`
reply, or poll `history.sh` after a short delay. Retry once for silent
members, then report:

- Reconnected: this session (watcher confirmed streaming)
- Broadcast targets: watcher confirmed streaming, or silent (offline, not in
  monitor mode, or still starting)

Keep the report short.