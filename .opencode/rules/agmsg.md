<!-- agmsg-delivery-mode: monitor -->
# agmsg Integration Rule

## Real-time inbox watcher

At session start (or the first time you run /agmsg this session), launch a
resident inbox watcher with the `sentinel_monitor` tool so incoming agmsg
messages stream into this conversation as they arrive:

- command: '/Users/naphat/.agents/skills/agmsg/scripts/watch.sh' "${SENTINEL_SESSION_ID:--}" /Users/naphat/.config/dotfiles opencode
- description: agmsg inbox stream

Do not launch it more than once per session — if a watcher is already
streaming, skip this step.

### Fallback (no sentinel_monitor tool)

If the `sentinel_monitor` tool is not available, fall back to a turn-based
self-check instead: after each tool call, run
'/Users/naphat/.agents/skills/agmsg/scripts/check-inbox.sh' 'opencode' /Users/naphat/.config/dotfiles
to check the agmsg inbox for unread messages.
