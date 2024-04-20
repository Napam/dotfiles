# Setup fzf
# ---------
if [[ ! "$PATH" == */Users/naphat/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/Users/naphat/.fzf/bin"
fi

eval "$(fzf --bash)"
