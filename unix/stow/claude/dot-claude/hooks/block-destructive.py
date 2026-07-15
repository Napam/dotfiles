#!/usr/bin/env python3
"""Claude Code PreToolUse guard for Bash.

Blocks catastrophic, hard-to-reverse shell commands (recursive removal of root
/ $HOME / system dirs, disk wipes, fork bombs, ...). This exists because literal
`Bash(rm -rf /)` deny rules in settings.json only match an exact string and are
trivially sidestepped (flag reorder, trailing space, ~/$HOME, /bin, ...). A real
parser catches the *intent* instead.

Contract: reads the hook payload JSON on stdin, prints a PreToolUse deny
decision and exits 0 when a command looks catastrophic; otherwise prints nothing
and exits 0 so the normal permission flow proceeds. Fails open on any internal
error — this is a seatbelt, not a sandbox.
"""

import json
import os
import re
import shlex
import sys

HOME = os.path.expanduser("~").rstrip("/")

# Command words that can precede the real command (sudo flags handled below).
WRAPPERS = {
    "sudo", "doas", "command", "exec", "nice", "ionice", "time",
    "env", "nohup", "builtin", "setsid", "stdbuf",
}

# Top-level dirs whose recursive removal is effectively unrecoverable.
SYSTEM_DIRS = {
    "bin", "sbin", "etc", "usr", "var", "lib", "lib64", "boot", "sys",
    "proc", "dev", "opt", "root", "home", "users", "system", "applications",
    "library", "private", "tmp",
}

# Whole-command patterns (matched against the raw command string). Only for
# shell *syntax* that doesn't survive tokenization; command-word checks live in
# check_segment so a quoted mention (commit message, echo, grep) never matches.
CATASTROPHIC = [
    (r":\s*\(\s*\)\s*\{\s*:\s*\|\s*:\s*&\s*\}\s*;\s*:", "fork bomb"),
]

RAW_DISK = re.compile(r"^/dev/(?:disk|rdisk|sd|nvme|hd|mmcblk|vd)\w*$")


def deny(reason):
    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "deny",
            "permissionDecisionReason": (
                "Blocked by block-destructive hook: " + reason +
                ". Run it yourself if you're certain."
            ),
        }
    }))
    sys.exit(0)


def normalize_target(tok):
    """Expand ~ and $HOME so home-relative targets are comparable."""
    t = tok
    if t == "~" or t.startswith("~/"):
        t = HOME + t[1:]
    t = t.replace("${HOME}", HOME).replace("$HOME", HOME)
    return t


def is_dangerous_target(tok):
    t = normalize_target(tok)
    if t in ("/", "/*") or t.startswith("/*"):
        return True
    if HOME and (t.rstrip("/") == HOME or t == HOME + "/*"):
        return True
    # /<top> or /<top>/ or /<top>/* — a single system directory
    m = re.match(r"^/([^/]+)/?\*?$", t)
    if m and m.group(1).lower() in SYSTEM_DIRS:
        return True
    return False


def check_segment(tokens):
    """tokens = argv of one simple command. Returns a reason str or None."""
    i = 0
    # Skip leading VAR=value assignments.
    while i < len(tokens) and re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", tokens[i]):
        i += 1
    # Skip wrapper commands and the options they carry. Some short options take
    # a value in the *next* token (e.g. `sudo -u root`, `env` VAR= assignments),
    # which must also be skipped so the value isn't mistaken for the command.
    valued_opt = re.compile(r"^-[ugphrtTCUcRD]$")
    while i < len(tokens):
        base = tokens[i].split("/")[-1].lstrip("\\")
        if base not in WRAPPERS:
            break
        i += 1
        while i < len(tokens):
            t = tokens[i]
            if t.startswith("-"):
                i += 1
                if valued_opt.match(t):
                    i += 1  # skip this option's value
            elif re.match(r"^[A-Za-z_][A-Za-z0-9_]*=", t):
                i += 1  # env-style VAR=value before the command
            else:
                break
    if i >= len(tokens):
        return None
    cmd = tokens[i].split("/")[-1].lstrip("\\")
    argv = tokens[i:]

    if cmd == "mkfs" or cmd.startswith("mkfs."):
        return "mkfs reformats a filesystem"
    if cmd in ("wipefs", "blkdiscard"):
        return "wipes a block device / filesystem signatures"
    if cmd == "dd":
        for a in argv[1:]:
            if a.startswith("of=") and RAW_DISK.match(a[3:]):
                return "dd writing to a raw disk device"
        return None
    # Redirect onto a raw disk device: shlex yields ">" "/dev/sd..." or ">/dev/sd..."
    for j, a in enumerate(argv):
        if a == ">" and j + 1 < len(argv) and RAW_DISK.match(argv[j + 1]):
            return "redirecting output onto a raw disk device"
        if a.startswith(">") and RAW_DISK.match(a[1:]):
            return "redirecting output onto a raw disk device"

    if cmd != "rm":
        return None

    recursive = force = no_preserve = opts_done = False
    targets = []
    for a in tokens[i + 1:]:
        if not opts_done and a == "--":
            opts_done = True
            continue
        if not opts_done and a.startswith("--"):
            if a == "--recursive":
                recursive = True
            elif a == "--force":
                force = True
            elif a == "--no-preserve-root":
                no_preserve = True
            continue
        if not opts_done and len(a) > 1 and a.startswith("-"):
            letters = a[1:]
            if "r" in letters or "R" in letters:
                recursive = True
            if "f" in letters:
                force = True
            continue
        targets.append(a)

    if no_preserve:
        return "rm --no-preserve-root"
    if recursive:
        for t in targets:
            if is_dangerous_target(t):
                flags = "-" + ("r" if recursive else "") + ("f" if force else "")
                return "recursive rm ({}) of {!r}".format(flags, t)
    return None


def main():
    try:
        payload = json.load(sys.stdin)
    except Exception:
        sys.exit(0)

    if payload.get("tool_name") != "Bash":
        sys.exit(0)
    cmd = (payload.get("tool_input") or {}).get("command", "")
    if not isinstance(cmd, str) or not cmd.strip():
        sys.exit(0)

    for pattern, reason in CATASTROPHIC:
        if re.search(pattern, cmd, re.IGNORECASE):
            deny(reason)

    # Split into simple commands on shell operators, then argv-tokenize each.
    for seg in re.split(r"\|\||&&|;|\||&|\n", cmd):
        seg = seg.strip()
        if not seg:
            continue
        try:
            tokens = shlex.split(seg, comments=True)
        except ValueError:
            tokens = seg.split()
        if not tokens:
            continue
        reason = check_segment(tokens)
        if reason:
            deny(reason)

    sys.exit(0)


if __name__ == "__main__":
    main()
