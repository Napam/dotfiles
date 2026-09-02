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

# Adapter for MacOS — returns gnu variant if available (gsed, gxargs, etc.)
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

# 690794496 -> "658M"
humanbytes() {
  local n=$1 u=B i=0
  while ((n >= 1024 && i < 3)); do
    n=$((n / 1024))
    ((i++))
  done
  case $i in 1) u=K ;; 2) u=M ;; 3) u=G ;; esac
  printf '%s%s' "$n" "$u"
}

# WARN: deletes opencode sessions older than DURATION (e.g. 1w, 2 weeks, 30d). Irreversible.
ocsessprune() {
  local duration=${1:-} cutoff

  if [[ -z $duration ]]; then
    echo "ocsessprune: no timeframe given. Usage: ocsessprune <duration>, e.g. 1w, 2 weeks, 30d, 3h" >&2
    return 1
  fi

  # GNU date parses "1 week"; BSD date (macOS) can't, so gnuify gives us gdate (or GNU date on Linux).
  local datecmd
  datecmd=$(gnuify date)
  if ! cutoff=$("$datecmd" -d "-$duration" +%s 2> /dev/null); then
    echo "ocsessprune: bad duration '$duration' (use e.g. 1w, 2 weeks, 30d)" >&2
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

  local cutoff_ms json ids
  cutoff_ms=$((cutoff * 1000))
  if ! json=$(opencode session list --format json); then
    echo "ocsessprune: opencode session list failed" >&2
    return 1
  fi
  ids=$(jq -r --argjson cutoff "$cutoff_ms" '.[] | select(.created < $cutoff) | .id' <<< "$json") || return 1

  if [[ -z $ids ]]; then
    echo "ocsessprune: no sessions older than $duration"
    return 0
  fi

  # Session rows are tiny; nearly all DB bytes are event/message/part payloads.
  local db db_before
  db=$HOME/.local/share/opencode/opencode.db
  declare -A bytes=()
  if [[ -f $db ]] && command -v sqlite3 > /dev/null; then
    while IFS='|' read -r id sz; do bytes[$id]=$sz; done < <(
      sqlite3 "$db" "
        SELECT s.id,
          COALESCE((SELECT SUM(LENGTH(e.data)) FROM event e WHERE e.aggregate_id = s.id), 0)
          + COALESCE((SELECT SUM(LENGTH(m.data)) FROM message m WHERE m.session_id = s.id), 0)
          + COALESCE((SELECT SUM(LENGTH(p.data)) FROM part p WHERE p.session_id = s.id), 0)
        FROM session s;" 2> /dev/null
    )
  fi

  local count total=0 id
  count=$(wc -l <<< "$ids" | tr -d ' ')
  while IFS= read -r id; do ((total += ${bytes[$id]:-0})); done <<< "$ids"

  echo "Deleting $count opencode session(s) older than $duration (~$(humanbytes "$total")):"
  jq -r --argjson cutoff "$cutoff_ms" '.[] | select(.created < $cutoff) | "\(.id)\t\(.title)"' <<< "$json" |
    while IFS=$'\t' read -r sid title; do
      printf '  - %s [%s] (%s)\n' "$title" "$sid" "$(humanbytes "${bytes[$sid]:-0}")"
    done

  local confirm
  printf "Proceed? (y/n): "
  read -r confirm
  if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "ocsessprune: cancelled"
    return 0
  fi

  local rc=0 db_after
  db_before=$(stat -f%z "$db" 2> /dev/null || stat -c%s "$db" 2> /dev/null)

  while IFS= read -r id; do
    opencode session delete "$id" > /dev/null || rc=1
  done <<< "$ids"

  # CLI can't list subagent sessions, so clean orphaned ones (parent already gone) via sqlite.
  # WARN: if opencode changes the schema, the count query fails -> treated as 0, nothing wiped.
  local orphans
  orphans=0
  if [[ -f $db ]] && command -v sqlite3 > /dev/null; then
    orphans=$(sqlite3 "$db" "SELECT COUNT(*) FROM session WHERE parent_id IS NOT NULL AND parent_id NOT IN (SELECT id FROM session);" 2> /dev/null)
    if ((orphans > 0)); then
      if sqlite3 "$db" "
        PRAGMA foreign_keys=ON;
        DELETE FROM event_sequence WHERE aggregate_id IN (SELECT id FROM session WHERE parent_id IS NOT NULL AND parent_id NOT IN (SELECT id FROM session));
        DELETE FROM session WHERE parent_id IS NOT NULL AND parent_id NOT IN (SELECT id FROM session);"; then
        echo "Removed $orphans orphaned subagent session(s)."
      else
        echo "ocsessprune: orphan subagent cleanup failed (schema changed?). Skipping." >&2
      fi
    fi
  fi

  if [[ -f $db ]] && command -v sqlite3 > /dev/null && sqlite3 "$db" VACUUM; then
    db_after=$(stat -f%z "$db" 2> /dev/null || stat -c%s "$db" 2> /dev/null)
    if [[ -n $db_before && -n $db_after ]]; then
      local freed=$((db_before - db_after))
      if ((freed > 0)); then
        echo "Done ($rc failures). Freed $(humanbytes "$freed") ($(humanbytes "$db_before") -> $(humanbytes "$db_after"))."
      else
        echo "Done ($rc failures). No space reclaimed ($(humanbytes "$db_before") -> $(humanbytes "$db_after"))."
        echo "Deleted sessions held ~$(humanbytes "$total"); the rest is live sessions' event logs."
      fi
    else
      echo "Done ($rc failures). VACUUM ran, size unknown (stat failed)."
    fi
  else
    echo "Done ($rc failures). VACUUM skipped (sqlite3 missing, db not found, or vacuum failed). Run 'sqlite3 ~/.local/share/opencode/opencode.db VACUUM;' manually."
  fi
  return $rc
}

# WARN: deletes opencode2 sessions older than DURATION via API only. Irreversible.
ocsessprune2() {
  local duration=${1:-} cutoff

  if [[ -z $duration ]]; then
    echo "ocsessprune2: no timeframe given. Usage: ocsessprune2 <duration>, e.g. 1w, 2 weeks, 30d, 3h" >&2
    return 1
  fi

  # GNU date parses "1 week"; BSD date (macOS) can't, so gnuify gives us gdate (or GNU date on Linux).
  # It does not parse shorthands like 1w/30d/3h, so expand a trailing unit letter first.
  local datecmd spec
  datecmd=$(gnuify date)
  spec=$duration
  case $spec in
    *' '*) ;;
    *)
      local num=${spec%?} unit=${spec#"${spec%?}"}
      case $unit in
        s|m|h|d|w|y)
          case $num in
            ''|*[!0-9]*) ;;
            *)
              case $unit in
                s) spec="$num sec" ;;
                m) spec="$num minutes" ;;
                h) spec="$num hours" ;;
                d) spec="$num days" ;;
                w) spec="$num weeks" ;;
                y) spec="$num years" ;;
              esac ;;
          esac ;;
      esac ;;
  esac
  if ! cutoff=$("$datecmd" -d "-$spec" +%s 2> /dev/null); then
    echo "ocsessprune2: bad duration '$duration' (use e.g. 1w, 2 weeks, 30d)" >&2
    return 1
  fi

  if ! command -v opencode2 > /dev/null; then
    echo "ocsessprune2: opencode2 not found" >&2
    return 1
  fi
  if ! command -v jq > /dev/null; then
    echo "ocsessprune2: jq not found" >&2
    return 1
  fi

  local cutoff_ms=$((cutoff * 1000))

  # Page through the API; each page is {data:[...], cursor:{next}}. No sqlite.
  local cursor="" page page_data next
  local all_data="[]"
  while true; do
    if [[ -z $cursor ]]; then
      page=$(opencode2 api get "/api/session?limit=100") || {
        echo "ocsessprune2: session list failed" >&2
        return 1
      }
    else
      page=$(opencode2 api get "/api/session?limit=100&cursor=$cursor") || {
        echo "ocsessprune2: session list failed" >&2
        return 1
      }
    fi
    page_data=$(jq -c '.data // []' <<< "$page") || return 1
    all_data=$(jq -c --argjson a "$all_data" --argjson b "$page_data" -n '$a + $b') || return 1
    next=$(jq -r '.cursor.next // empty' <<< "$page") || return 1
    if [[ -z $next ]]; then
      break
    fi
    cursor=$next
  done

  local ids
  ids=$(jq -r --argjson cutoff "$cutoff_ms" '.[] | select(.time.created < $cutoff) | .id' <<< "$all_data") || return 1

  if [[ -z $ids ]]; then
    echo "ocsessprune2: no sessions older than $duration"
    return 0
  fi

  local count
  count=$(wc -l <<< "$ids" | tr -d ' ')
  local tok_in tok_out cost
  tok_in=$(jq --argjson cutoff "$cutoff_ms" '[.[] | select(.time.created < $cutoff) | .tokens.input // 0] | add // 0' <<< "$all_data")
  tok_out=$(jq --argjson cutoff "$cutoff_ms" '[.[] | select(.time.created < $cutoff) | .tokens.output // 0] | add // 0' <<< "$all_data")
  cost=$(jq --argjson cutoff "$cutoff_ms" '[.[] | select(.time.created < $cutoff) | .cost // 0] | add // 0' <<< "$all_data")

  echo "Deleting $count opencode2 session(s) older than $duration (in-tokens: $tok_in, out-tokens: $tok_out, cost: \$$cost):"
  jq -r --argjson cutoff "$cutoff_ms" '.[] | select(.time.created < $cutoff) | "\(.id)\t\(.title // "untitled")\t\(.time.created)"' <<< "$all_data" |
    while IFS=$'\t' read -r sid title created; do
      printf '  - %s [%s] (%s)\n' "$title" "$sid" "$("$datecmd" -d "@$((created / 1000))" +%F 2> /dev/null || echo "$created")"
    done

  local confirm
  printf "Proceed? (y/n): "
  read -r confirm
  if [[ $confirm != [yY] && $confirm != [yY][eE][sS] ]]; then
    echo "ocsessprune2: cancelled"
    return 0
  fi

  local rc=0 id
  while IFS= read -r id; do
    opencode2 api delete "/api/session/$id" > /dev/null || rc=1
  done <<< "$ids"

  # API delete cascades messages server-side; no orphan SQL, no VACUUM (server owns the DB/WAL).
  echo "Done ($rc failures). Deleted $count session(s)."
  return $rc
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
# WARN: undo via `defaults delete -g <key>` (see echo at end); re-running is safe.
# Caps Lock->Escape: not scripted. Set once in System Settings > Keyboard >
# "Modifier Keys..." (per-keyboard, survives reboot & reconnect).
setupmac() {
  [[ ${IS_MAC-} ]] || { echo "setupmac: macOS only" >&2; return 1; }

  defaults write -g ApplePressAndHoldEnabled                -bool false
  defaults write -g KeyRepeat                               -int  1
  defaults write -g InitialKeyRepeat                        -int  10
  defaults write -g NSAutomaticQuoteSubstitutionEnabled     -bool false
  defaults write -g NSAutomaticDashSubstitutionEnabled      -bool false
  defaults write -g NSAutomaticPeriodSubstitutionEnabled    -bool false
  defaults write -g NSAutomaticCapitalizationEnabled        -bool false
  defaults write -g NSAutomaticSpellingCorrectionEnabled    -bool false
  defaults write -g NSAutomaticTextCompletionEnabled        -bool false
  defaults write -g AppleKeyboardUIMode                     -int  2

  cat << 'EOM'
setupmac: done.
- Full effect needs a log out & back in, or restart open apps.
- Revert quotes/repeat/correction changes with:
    defaults delete -g ApplePressAndHoldEnabled KeyRepeat InitialKeyRepeat AppleKeyboardUIMode NSAutomaticQuoteSubstitutionEnabled NSAutomaticDashSubstitutionEnabled NSAutomaticPeriodSubstitutionEnabled NSAutomaticCapitalizationEnabled NSAutomaticSpellingCorrectionEnabled NSAutomaticTextCompletionEnabled
- Caps Lock->Escape: set once in System Settings > Keyboard > "Modifier Keys..."
  (per-keyboard, survives reboot & reconnect).
EOM
}
