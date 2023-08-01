# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/naphat/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/Users/naphat/.fzf/bin"
fi

# Auto-completion
# ---------------
[[ $- == *i* ]] && source "/Users/naphat/.fzf/shell/completion.bash" 2> /dev/null

# Key bindings
# ------------
source "/Users/naphat/.fzf/shell/key-bindings.bash"
