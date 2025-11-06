#!/bin/bash

current_session_name=$(tmux display-message -p '#S')
pane_path=$(tmux display-message -p '#{pane_current_path}')
pane_program=$(tmux display-message -p '#{pane_current_command}')

if git -C "$pane_path" rev-parse --show-toplevel &> /dev/null; then
    git_root=$(git -C "$pane_path" rev-parse --show-toplevel)
    base_name="$(basename "$git_root") "
else
    base_name=$(basename "$pane_path")
fi

session_name="$base_name | $pane_program"
counter=2

# Check if session name exists (excluding current session)
while tmux has-session -t "=$session_name" 2> /dev/null; do
    # If the existing session is the current one, we're done
    if [ "$session_name" = "$current_session_name" ]; then
        break
    fi

    # Otherwise, try with a counter suffix
    session_name="${base_name} | $pane_program (${counter})"
    counter=$((counter + 1))
done

# Only rename if the name is different
if [ "$session_name" != "$current_session_name" ]; then
    tmux rename-session -t "$current_session_name" "$session_name"
fi
