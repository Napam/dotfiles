# shellcheck shell=bash disable=SC1090,SC1091,SC2154
# Aliases + interactive utility functions. Sourced from shellrc.sh.
# SC2154: alias-internal loop var (repo) is assigned at alias-use time, not statically.
#

if ls --color=auto / > /dev/null 2>&1; then alias ls='ls --color=auto'; fi
alias weeknr='date +%U'
alias hostpwd='python3 -m http.server 7100'
alias edithosts='sudo vim /etc/hosts'
[[ ${IS_WSL-} ]] && alias pwdc='pwd; pwd | clip.exe'
[[ ${IS_WSL-} ]] && alias updatehosts='updatewslhosts && updatewinhosts'
[[ ${IS_WSL-} ]] && alias editwinhosts='sudo vim /mnt/c/Windows/System32/drivers/etc/hosts'
[[ ${IS_WSL-} ]] && alias winpwd='wslpath -w $(pwd)'

update() {
  local rc=0 ran=0

  if command -v brew &> /dev/null; then
    ran=1
    echo "==> brew"
    brew update && brew bundle -g && brew upgrade -y && brew cleanup && brew autoremove || rc=1
  fi

  if command -v apt-get &> /dev/null; then
    ran=1
    echo "==> apt-get"
    sudo apt-get update \
      && sudo apt-get dist-upgrade -y \
      && sudo apt-get autoremove -y \
      && sudo apt-get autoclean || rc=1
  fi

  if command -v dnf &> /dev/null; then
    ran=1
    echo "==> dnf"
    sudo dnf upgrade --refresh -y && sudo dnf autoremove -y || rc=1
  fi

  if command -v mise &> /dev/null; then
    ran=1
    echo "==> mise"
    # -C $HOME: scope to global config; plain run in a repo dir would bump that repo's tools
    mise upgrade -C "$HOME" || rc=1
  fi

  if ((!ran)); then
    echo "update: no supported package manager found (brew, apt-get, dnf, or mise)" >&2
    return 1
  fi
  return $rc
}

# WARN: source the matching rc for current shell, not hardcoded zshrc
refresh() {
  case ${_RC_SHELL:-} in
    bash) source "$HOME/.bashrc" ;;
    zsh)  source "$HOME/.zshrc" ;;
    *)
      echo "refresh: unknown shell ($_RC_SHELL)" >&2
      return 1
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
    | awk -F/ 'tolower($NF)~/english/{a[$2]=$0} END{for(key in a){print a[key]; print key".srt"}}' \
    | while IFS= read -r eng && IFS= read -r srt; do
        printf '%s %s\n' "$eng" "$srt"
    done
}

[[ ${IS_WSL-} ]] && alias fixwin='sudo update-binfmts --disable cli'
alias feh='feh --auto-reload'
[[ ${IS_LINUX-} ]] && alias safeupgrade='sudo aptitude safe-upgrade'
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
      echo -E "$line" | sed -E 's/^>[ ]*//' | jq -C
    else
      echo "$line"
    fi
  done
}

alias editutils='vim $HOME/.config/dotfiles/unix/shellutils.sh && source $HOME/.config/dotfiles/unix/shellutils.sh'
alias editenv='vim $HOME/.config/dotfiles/unix/shellenv.sh && source $HOME/.config/dotfiles/unix/shellenv.sh'
alias editvimrc='vim $HOME/.config/nvim/init.lua'
alias editlocalrc='vim $HOME/.localrc && source $HOME/.localrc'
# WARN: $_RC_SHELL expands at alias-use time (alias body is re-parsed), so
# sourcing the right rc per current shell works in both bash and zsh.
alias editrc='vim $(realpath $HOME/.${_RC_SHELL}rc) && source $HOME/.${_RC_SHELL}rc'
alias editshellrc='vim $HOME/.config/dotfiles/unix/shellrc.sh && source $(realpath $HOME/.${_RC_SHELL}rc)'
alias dots='cd $HOME/.config/dotfiles'
alias conf='cd $HOME/.config'
alias nvimconf='cd $HOME/.config/dotfiles/unix/stow/vim/dot-config/nvim'

alias k='kubectl'
alias k3='k3s kubectl'

azaccset() {
  local sub
  sub=$(az account list -o table | fzf --header-lines 2 | awk -F'[[:space:]][[:space:]]+' '{print $3}')
  [[ -n $sub ]] && az account set -s "$sub"
}

alias pullrepos='for repo in */; do printf "Pulling \e[33m${repo%/}\e[0m\n"; git -C "${repo%/}" pull; done'
alias gd='git diff'
alias gl='git log'
alias gacm='git add . && git commit -m'
alias gspp='git stash && git pull && git stash pop'
alias gp='git pull'
alias cdgr='cd $(git rev-parse --show-toplevel)'
alias lgit='lazygit'
alias ldots='lazygit -p $HOME/.config/dotfiles'

alias tks='tmux kill-server'

alias hss='herdr server stop'
alias hsr='herdr server reload-config'

readwhich() {
  readlink -f "$(which "$1")"
}

# Adapter for MacOS: returns gnu variant if available (gsed, gxargs, etc.)
gnuify() {
  if command -v "g$1" > /dev/null; then
    echo "g$1"
  else
    echo "$1"
  fi
}

daystony() {
  local datecmd nydate nysec now ndays
  datecmd=$(gnuify date)
  nydate=$(($( "$datecmd" +%Y) + 1))/01/01
  if ! nysec=$("$datecmd" -d "$nydate" +%s 2> /dev/null); then
    echo "daystony: date -d not supported (install coreutils)" >&2
    return 1
  fi
  now=$("$datecmd" +%s)
  ndays=$(((nysec - now + 86399) / 86400))
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

# WARN: deletes opencode sessions older than DURATION via `opencode session delete`. Irreversible.
ocsessprune() {
  local duration=$* cutoff now spec

  if [[ -z $duration ]]; then
    echo "ocsessprune: no timeframe given. Usage: ocsessprune <duration>, e.g. 1w, 2 weeks, 30d, 3h" >&2
    return 1
  fi

  local datecmd num unit
  datecmd=$(gnuify date)
  spec=${duration%ago}
  spec=${spec% }
  num=${spec%?}
  unit=${spec#"$num"}
  case $num in
    ''|*[!0-9]*) ;;
    *)
      case $unit in
        s) spec="$num seconds" ;;
        m) spec="$num minutes" ;;
        h) spec="$num hours" ;;
        d) spec="$num days" ;;
        w) spec="$num weeks" ;;
        y) spec="$num years" ;;
      esac ;;
  esac

  if ! "$datecmd" -d "1 day" +%s > /dev/null 2>&1; then
    echo "ocsessprune: GNU date is required; install coreutils (gdate on macOS)" >&2
    return 1
  fi
  if ! cutoff=$("$datecmd" -d "-$spec" +%s 2> /dev/null); then
    echo "ocsessprune: bad duration '$duration' (use e.g. 1w, 2 weeks, 30d)" >&2
    return 1
  fi
  now=$("$datecmd" +%s) || return 1
  if ((cutoff >= now)); then
    echo "ocsessprune: duration must be greater than zero" >&2
    return 1
  fi

  if ! command -v opencode > /dev/null; then
    echo "ocsessprune: opencode not found" >&2
    return 1
  fi
  if ! command -v jq > /dev/null; then
    echo "ocsessprune: jq not found" >&2
    return 1
  fi

  local cutoff_ms=$((cutoff * 1000))
  local active
  if ! active=$(opencode api get "/api/session/active"); then
    echo "ocsessprune: active session list failed" >&2
    return 1
  fi
  if ! active=$(jq -ce '.data | objects' <<< "$active" 2> /dev/null); then
    echo "ocsessprune: invalid active session response" >&2
    return 1
  fi

  # WARN: every page must parse; a dropped page could hide a newer child of an old root.
  local cursor="" page pages=""
  while true; do
    if ! page=$(opencode api get "/api/session?limit=100&order=asc${cursor:+&cursor=$cursor}"); then
      echo "ocsessprune: session list failed" >&2
      return 1
    fi
    # WARN: cursor is base64; "+" and "/" must be escaped in the query string
    if ! cursor=$(jq -r 'if (.data | type) == "array" then .cursor.next // "" | @uri else error end' <<< "$page" 2> /dev/null); then
      echo "ocsessprune: invalid session list response" >&2
      return 1
    fi
    pages+="$page"$'\n'
    if [[ -z $cursor ]]; then
      break
    fi
  done

  # Group each session under its topmost known ancestor; a missing parent makes it a root.
  local selected
  if ! selected=$(jq -s -c --argjson cutoff "$cutoff_ms" --argjson active "$active" '
    map(.data) | add // []
    | INDEX(.id) as $by_id
    | def root: .parentID as $p | if $p and $by_id[$p] then $by_id[$p] | root else . end;
      group_by(root.id)
    | map({
        session: (.[0] | root),
        members: .,
        latest: (map(.time.updated // .time.created // 0) | max),
        child_count: (length - 1),
        cost: (map(.cost // 0) | add)
      })
    | map(select(.latest < $cutoff and all(.members[]; $active[.id] == null)))
    | sort_by(.latest)
  ' <<< "$pages"); then
    echo "ocsessprune: failed to select sessions" >&2
    return 1
  fi

  if [[ $selected == '[]' ]]; then
    echo "ocsessprune: no inactive sessions older than $duration"
    return 0
  fi

  # Read-only size estimate. Freed pages stay in the file (auto_vacuum off) until VACUUM.
  # WARN: a schema change yields {} and the size columns are hidden, not shown as 0.
  local db=$HOME/.local/share/opencode/opencode.db bytes=''
  if [[ -f $db ]] && command -v sqlite3 > /dev/null; then
    bytes=$(sqlite3 "file:$db?mode=ro" "SELECT json_group_object(session_id, n) FROM
      (SELECT session_id, SUM(LENGTH(data)) n FROM session_message GROUP BY session_id);" 2> /dev/null)
  fi
  if [[ -z $bytes ]]; then
    bytes='{}'
  fi

  local cutoff_date color=false bold='' dim='' green='' red='' reset=''
  cutoff_date=$("$datecmd" -d "@$cutoff" +%F) || return 1
  if [[ -t 1 && -z ${NO_COLOR-} ]]; then
    color=true bold=$'\e[1m' dim=$'\e[2m' green=$'\e[32m' red=$'\e[31m' reset=$'\e[0m'
  fi
  if ! jq -r --arg home "$HOME" --arg cutoff_date "$cutoff_date" --argjson bytes "$bytes" \
    --argjson color "$color" '
    def c($code): if $color then "\u001b[\($code)m\(.)\u001b[0m" else . end;
    def spaces($n): " " * ([$n, 0] | max) // "";
    def rpad($n): tostring | . + spaces($n - length);
    def lpad($n): tostring | spaces($n - length) + .;
    def trunc($n): if length > $n then .[:$n - 1] + "…" else . end;
    def usd: ((. // 0) * 100 | round) as $c
      | "$\($c / 100 | floor).\($c % 100 | tostring | if length < 2 then "0" + . else . end)";
    def total(f): [.[].members[] | f // 0] | add;
    def size: [.members[] | $bytes[.id] // 0] | add;
    def short($base):
      if . >= $base * $base * $base then "\(. / ($base * $base * $base) * 10 | floor / 10)G"
      elif . >= $base * $base then "\(. / ($base * $base) * 10 | floor / 10)M"
      elif . >= $base then "\(. / $base | floor)K"
      else tostring
      end;
    def home_dir:
      if . == null or . == "" then "(no directory)"
      elif . == $home or startswith($home + "/") then "~" + ltrimstr($home)
      else .
      end;
    def clean_title:
      ((. // "") | tostring | gsub("[\\t\\r\\n]"; " ") | if . == "" then "untitled" else . end);
    30 as $cap
    | ($bytes | length > 0) as $sized
    | map(. + {size: size, name: (.session.title | clean_title | trunc(40))})
    | (.[:$cap] | map(.name | length) | max) as $name_width
    | ("Delete \(length) session(s) (+\(map(.child_count) | add) subagents), last active before \($cutoff_date)"
        | c("1")),
      "",
      (.[:$cap][] |
        "  " + ((.latest / 1000) | strftime("%F") | c("2"))
        + "  " + (.cost | usd | lpad(7) | c("33"))
        + (if $sized then "  " + (.size | short(1024) | lpad(5) | c("36")) else "" end)
        + "  " + ((if .child_count > 0 then "+\(.child_count)" else "" end) | lpad(3) | c("2"))
        + "  " + (.name | rpad($name_width))
        + "  " + (.session.location.directory | home_dir | c("2"))),
      (if length > $cap then "  … and \(length - $cap) more" | c("2") else empty end),
      "",
      "  " + ("Total" | c("1"))
        + "  " + (total(.cost) | usd | c("33"))
        + (if $sized then " · " + (map(.size) | add | short(1024) | c("36")) else "" end)
        + " · " + ("\(total(.tokens.input) | short(1000)) in / \(total(.tokens.output) | short(1000)) out tokens" | c("2")),
      (if $sized then "  Size is session data inside the DB; the file shrinks only after VACUUM." | c("2") else empty end),
      ""
  ' <<< "$selected"; then
    echo "ocsessprune: failed to render summary" >&2
    return 1
  fi

  local confirm
  printf '%sProceed?%s [y/N] ' "$bold" "$reset"
  read -r confirm
  if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "ocsessprune: cancelled"
    return 0
  fi

  local ids deleted=0 failed=0 id failure
  ids=$(jq -r '.[].session.id' <<< "$selected") || return 1
  while IFS= read -r id; do
    if failure=$(opencode session delete "$id" 2>&1 < /dev/null); then
      deleted=$((deleted + 1))
    else
      failed=$((failed + 1))
      echo "ocsessprune: failed to delete $id${failure:+: $failure}" >&2
    fi
  done <<< "$ids"

  if ((failed == 0)); then
    printf '%s✓ Deleted %s session(s) and their subagents%s\n' "$green" "$deleted" "$reset"
  else
    printf '%s✗ Deleted %s session(s), %s failed%s\n' "$red" "$deleted" "$failed" "$reset"
  fi

  if ((deleted == 0)) || [[ ! -f $db ]] || ! command -v sqlite3 > /dev/null; then
    return $((failed > 0))
  fi

  local size_before free_bytes free_human
  size_before=$(du -h "$db" | awk '{print $1}')
  IFS='|' read -r free_bytes free_human < <(sqlite3 "file:$db?mode=ro" "SELECT n, printf('%.1fM', n / 1048576.0)
    FROM (SELECT freelist_count * page_size n FROM pragma_freelist_count(), pragma_page_size());" 2> /dev/null)
  if [[ -n $free_bytes ]] && ((free_bytes < 1048576)); then
    return $((failed > 0))
  fi

  echo
  printf '%sShrink opencode.db?%s %s now%s\n' "$bold" "$reset" "$size_before" "${free_human:+, ~$free_human reclaimable}"
  printf '%s  Runs VACUUM and restarts the opencode server. Open opencode windows disconnect.%s\n' "$dim" "$reset"
  printf '%sVacuum?%s [y/N] ' "$bold" "$reset"
  read -r confirm
  if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    return $((failed > 0))
  fi

  printf '%s  Stopping server…%s\n' "$dim" "$reset"
  if ! opencode service stop > /dev/null; then
    printf '%s✗ Could not stop the opencode server; skipped VACUUM%s\n' "$red" "$reset" >&2
    return 1
  fi
  # WARN: VACUUM needs the server's connection closed; restart it even if VACUUM fails.
  printf '%s  Vacuuming…%s\n' "$dim" "$reset"
  if sqlite3 "$db" VACUUM; then
    printf '%s✓ opencode.db %s → %s%s\n' "$green" "$size_before" "$(du -h "$db" | awk '{print $1}')" "$reset"
  else
    printf '%s✗ VACUUM failed%s\n' "$red" "$reset" >&2
    failed=$((failed + 1))
  fi
  printf '%s  Starting server…%s\n' "$dim" "$reset"
  if ! opencode service start > /dev/null; then
    printf '%s✗ Could not start the opencode server; run: opencode service start%s\n' "$red" "$reset" >&2
    failed=$((failed + 1))
  fi
  return $((failed > 0))
}

genpass() {
  local length=${1:-16}
  local pass
  pass=$(openssl rand -base64 $((length * 2)) | tr -d '/=+\n' | cut -c1-"$length")
  echo "$pass"
}

localrctemplate() {
  cat << 'EOF'
# export LOCAL_TMUX=true
# export LOCAL_HERDR=true
# export LOCAL_PROMPT_SHOW_HOSTNAME=true
# export LOCAL_NVIM_PLUGIN_MODE=ALL
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
    bash) bash <<< 'for code in {0..255}; do printf "\e[38;05;%sm %03d" "$code" "$code"; [ $((code % 16)) -eq 15 ] && echo; done' ;;
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

function installubuntuessentials() {
  sudo apt install \
    mise \
    unzip \
    stow \
    gcc \
    git-delta
}

# Apply macOS defaults for terminal/nvim-first use.
# WARN: ApplePressAndHoldEnabled=false kills the long-press accent picker.
# WARN: per-app override possible; if an app still eats repeated keys:
#       defaults write <bundle-id> ApplePressAndHoldEnabled -bool false
# NOTE: adding a key here? add it to the revert list at the bottom too.
# Caps Lock->Escape: not scripted on purpose. hidutil doesn't survive hot-plug,
# and the defaults route needs per-keyboard vendor/product IDs. One GUI toggle
# is cheaper than either.
setupmackeyboard() {
  if [[ ! ${IS_MAC-} ]]; then
    echo "setupmac: macOS only" >&2
    return 1
  fi

  defaults write -g ApplePressAndHoldEnabled                -bool false
  defaults write -g KeyRepeat                               -int  2
  defaults write -g InitialKeyRepeat                        -int  12
  defaults write -g NSAutomaticQuoteSubstitutionEnabled     -bool false
  defaults write -g NSAutomaticDashSubstitutionEnabled      -bool false
  defaults write -g NSAutomaticPeriodSubstitutionEnabled    -bool false
  defaults write -g NSAutomaticCapitalizationEnabled        -bool false
  defaults write -g NSAutomaticSpellingCorrectionEnabled    -bool false
  defaults write -g NSAutomaticTextCompletionEnabled        -bool false
  defaults write -g AppleKeyboardUIMode                     -int  2

  cat << 'EOM'
setupmac: done.

TODO (manual, once per keyboard):
  Caps Lock->Escape: System Settings > Keyboard > "Modifier Keys..."
  Survives reboot & reconnect. Nothing else here needs your input.

- Full effect needs a log out & back in, or restart open apps.
- Revert with (defaults delete takes one key at a time):
    defaults delete -g ApplePressAndHoldEnabled
    defaults delete -g KeyRepeat
    defaults delete -g InitialKeyRepeat
    defaults delete -g NSAutomaticQuoteSubstitutionEnabled
    defaults delete -g NSAutomaticDashSubstitutionEnabled
    defaults delete -g NSAutomaticPeriodSubstitutionEnabled
    defaults delete -g NSAutomaticCapitalizationEnabled
    defaults delete -g NSAutomaticSpellingCorrectionEnabled
    defaults delete -g NSAutomaticTextCompletionEnabled
    defaults delete -g AppleKeyboardUIMode
EOM
}
