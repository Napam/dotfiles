# shellcheck shell=bash disable=SC1090,SC1091,SC2016,SC2154
# Aliases + interactive utility functions. Sourced from shellrc.sh.
# SC2016: $0/$1 inside single quotes are *intentional* — consumed by xargs/sh -c/bash -c.
# SC2154: alias-internal loop vars (i, repo, branch) are assigned at runtime, not statically.

# Moved from shellenv.sh (aliases are interactive-only)
command -v nvim &> /dev/null && alias vim=nvim
command -v jbang &> /dev/null && alias j!=jbang

alias ls='ls --color=auto'
alias update='sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'
alias weeknr='date +%U'
alias pwdc='pwd; pwd | clip.exe'
alias hostpwd='python3 -m http.server 7100'
alias updatehosts='updatewslhosts && updatewinhosts'
alias edithosts='sudo vim /etc/hosts'
alias editwinhosts='sudo vim /mnt/c/Windows/System32/drivers/etc/hosts'
alias winpwd='wslpath -w $(pwd)'

# WARN: source the matching rc for current shell, not hardcoded zshrc
refresh() {
  case ${_RC_SHELL:-} in
    bash) source "$HOME/.bashrc" ;;
    zsh)  source "$HOME/.zshrc" ;;
    *)
      echo "refresh: unknown shell ($_RC_SHELL)"
      return 1 >&2
      ;;
  esac
}

# bounty + 7.5 (lunch hours)
bountyplusharvest() { bounty | awk -F ':>>' '/currBalance/ {print $1, $NF + 7.5}'; }
bountyplus()        { bounty | awk -F'[: ]' '{decimal=($4 + ($5 / 60)) + 7.5; HH=int(decimal); MM=(decimal-HH)*60; print HH":"MM}'; }
xbounty()           { XLEDGER_API_KEY=$(pass apikeys/xledger) bounty; }
xbountyplus()       { xbounty | awk -F': ' '{print "xbountyplus: " $2 + 7.5}'; }

readysubs() {
  find Subs -maxdepth 2 | sort -r \
    | awk -F/ 'tolower($NF)~/english/{a[$2]=$0} END{for(key in a){print a[key], key".srt"}}' \
    | xargs -L 1 bash -c 'echo $0 $1'
}

alias fixwin='sudo update-binfmts --disable cli'
alias feh='feh --auto-reload'
alias safeupgrade='sudo aptitude safe-upgrade'
alias ansicolors='for i in {0..255}; do printf "\e[38;5;${i}mcolor%-5i\e[0m" $i ; if ! (( ($i + 1 ) % 8 )); then echo ; fi ; done'
alias passc='pass -c'
alias repos='cd $HOME/repos'
alias flutterwatch='writehook ".*.dart" "kill -USR2 \$(pgrep -f \"dart .*flutter_tools.snapshot .*run\")"'
alias scaffoldtypst='curl -fsSL https://raw.githubusercontent.com/Napam/typst-templates/main/scaffold.sh | bash -s'

alias tcpports='sudo lsof -Pn -iTCP -sTCP:LISTEN'
alias udpports='sudo lsof -iUDP -P -n | grep -Ev "(127|::1)"'

# Firebase log pretty-printer
prettyfire() {
  while read -r line; do
    if [[ $line =~ ^(\>\ *)?\{\" ]]; then
      echo -E "${line#">  "}" | jq -C
    else
      echo "$line"
    fi
  done
}

# dotfile shortcuts
alias editutils='vim $HOME/.config/dotfiles/unix/shellutils.sh && source $HOME/.config/dotfiles/unix/shellutils.sh'
alias editenv='vim $HOME/.config/dotfiles/unix/shellenv.sh && source $HOME/.config/dotfiles/unix/shellenv.sh'
alias editvimrc='vim $HOME/.config/nvim/init.lua'
alias editlocalrc='vim $HOME/.localrc && source $HOME/.localrc'
# WARN: $_RC_SHELL expands at alias-use time (alias body is re-parsed), so
# sourcing the right rc per current shell works in both bash and zsh.
alias editrc='vim $(realpath $HOME/.${_RC_SHELL}rc); source $HOME/.${_RC_SHELL}rc'
alias editshellrc='vim $HOME/.config/dotfiles/unix/shellrc.sh && source $(realpath $HOME/.${_RC_SHELL}rc)'
alias dots='cd $HOME/.config/dotfiles'
alias conf='cd $HOME/.config'
alias nvimconf='cd $HOME/.config/dotfiles/unix/stow/vim/dot-config/nvim'

# Kubernetes
alias k='kubectl'
alias k3='k3s kubectl'

# Azure
azaccset() {
  local sub
  sub=$(az account list -o table | fzf --header-lines 2 | awk -F'[[:space:]][[:space:]]+' '{print $3}')
  [[ -n $sub ]] && az account set -s "$sub"
}

# Git
alias pullrepos='for repo in `ls -1`; do printf "Pulling \e[33m$repo\e[0m\n"; git -C $repo pull; done'
alias gd='git diff'
alias gl='git log'
alias gacm='git add . && git commit -m'
alias gp='git pull'
alias cdgr='cd $(git rev-parse --show-toplevel)'
alias lgit='lazygit'
alias ldots='lazygit -p $HOME/.config/dotfiles'

# Tmux
alias tks='tmux kill-server'

readwhich() {
  readlink -f "$(which "$1")"
}

# Adapter for MacOS — returns gnu variant if available (gsed, gxargs, etc.)
gnuify() {
  if command -v "g$1" > /dev/null; then
    echo "g$1"
  else
    echo "$1"
  fi
}

daystony() {
  local datecmd nydate ndays
  datecmd=$(gnuify date)
  nydate=$(($( "$datecmd" +%Y) + 1))/01/01
  ndays=$((($( "$datecmd" -d "$nydate" +%s) - $("$datecmd" +%s) + 86399) / 86400))
  echo "Days to new year: $ndays"
}

splitlines() {
  local cumstring="" line
  local lines=0

  while IFS= read -r line; do
    ((lines++))
    if [[ -n $cumstring ]]; then
      cumstring+=$'\n'
    fi
    cumstring+="$line"
  done

  local middle=$(((lines + 1) / 2))
  head -n "$middle" <<< "$cumstring"
  echo
  tail -n +$((middle + 1)) <<< "$cumstring"
}

gitclean() {
  echo "Pruning stale tracking branches"
  git remote prune origin

  local todelete confirm
  todelete=$(git branch -v | awk '$3~/\[gone\]/ {print $1}')
  if [[ -z $todelete ]]; then
    printf "No branches to delete\n"
    return
  fi

  printf "Are you sure you want to delete:\n\e[33m%s\e[0m\n(y/n): " "$todelete"
  read -r confirm
  if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
    printf '%s\n' "$todelete" | xargs -r git branch -D
  else
    printf "Operation cancelled\n"
  fi
}

genpass() {
  local length=${1:-16}
  local pass
  pass=$(openssl rand -base64 "$length" | tr -d '/=+\n' | cut -c1-"$length")
  echo "$pass"
}

localrctemplate() {
  cat << 'EOF'
# export LOCAL_TMUX=true
# export LOCAL_PROMPT_SHOW_HOSTNAME=true
# export LOCAL_NVIM_PLUGIN_MODE="ALL"
#
# function _localrc_after() {
#     # Scripts to invoke after the main rc file has loaded
# }
EOF
}

# 256-color palette display (works in bash and zsh)
color256() {
  local target_shell=${1:-$(basename "$SHELL")}
  case $target_shell in
    bash) bash <<< 'for code in {0..255}; do echo -n "[38;05;${code}m $(printf %03d $code)"; [ $((${code} % 16)) -eq 15 ] && echo; done' ;;
    zsh)  zsh  <<< 'for code in {000..255}; do print -nP -- "%F{$code}$code %f"; [ $((${code} % 16)) -eq 15 ] && echo; done' ;;
    *)
      echo "error: Invalid argument ($target_shell)" >&2
      echo "Usage: color256 [bash|zsh]" >&2
      return 1
      ;;
  esac
}

color16() {
  echo "  On White(47)     On Black(40)     On Default     Color Code"
  local rows=(
    "1;37:White"
    "37:Light Gray"
    "1;30:Gray"
    "30:Black"
    "31:Red"
    "1;31:Light Red"
    "32:Green"
    "1;32:Light Green"
    "33:Brown"
    "1;33:Yellow"
    "34:Blue"
    "1;34:Light Blue"
    "35:Purple"
    "1;35:Pink"
    "36:Cyan"
    "1;36:Light Cyan"
  )
  local row code label pad
  for row in "${rows[@]}"; do
    code=${row%%:*}
    label=${row#*:}
    pad=$(printf '%-13s' "$label")
    printf '\033[47m\033[%sm  %s  \033[0m  \033[40m\033[%sm  %s  \033[0m  \033[%sm  %s  \033[0m  %s\n' \
      "$code" "$pad" "$code" "$pad" "$code" "$pad" "$code"
  done
}
