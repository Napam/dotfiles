# Custom aliases
alias update='sudo apt-get update -y && sudo apt-get upgrade -y && sudo apt-get dist-upgrade -y'
alias paste.exe='powershell.exe Get-Clipboard'
alias weeknr='date +%U'
alias jbook='jupyter notebook --no-browser --port 7000 --NotebookApp.token="" --NotebookApp.password=""'
alias pwdc='pwd; pwd | clip.exe'
alias hostpwd='python3 -m http.server 7100'
alias updatehosts='updatewslhosts && updatewinhosts'
alias edithosts='sudo vim /etc/hosts'
alias editwinhosts='sudo vim /mnt/c/Windows/System32/drivers/etc/hosts'
alias winpwd='wslpath -w $(pwd)'
alias jh8='export JAVA_HOME=/usr/lib/jvm/java-1.8.0-openjdk-amd64 && echo $JAVA_HOME'
alias jh11='export JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64 && echo $JAVA_HOME'
alias jh17='export JAVA_HOME=/usr/lib/jvm/java-1.17.0-openjdk-amd64 && echo $JAVA_HOME'
alias refresh='source $HOME/.zshrc'
alias fvim='_targetfzf vim f .'
alias fcat='_targetfzf cat f .'
alias fccat='_targetfzf ccat f .'
alias back='cd $HOME/work/backend'
alias front='cd $HOME/work/frontend'
alias proj='cd $HOME/work/projects'
alias utils='cd $HOME/work/utils'
alias bountyplusharvest='bounty | awk -F ":>>" "/currBalance/ {print \$1,\$NF+7.5}"'
alias bountyplus="bounty | awk -F'[: ]' '{decimal=(\$4 + (\$5 / 60)) + 7.5; HH=int(decimal); MM=(decimal-HH)*60; print HH\":\"MM}'"
alias dockerexec='docker ps -a --format="table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}" | fzf --header-lines 1 --no-sort | awk "{print \$1}" | xargs --open-tty -I{} docker exec -it {}'
alias dockerlogsf='docker ps -a --format="table {{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Ports}}" | fzf --header-lines 1 --no-sort | awk "{print \$1}" | xargs --open-tty -I{} docker logs -f {}'
alias dockerimagerm="docker images | fzf --header-lines 1 -m --no-sort | awk '{print \$3}' | xargs docker image rm"
alias readysubs="find Subs -maxdepth 2 | sort -r | awk -F/ 'tolower(\$NF)~/english/{a[\$2]=\$0} END{for(key in a){print a[key],key\".srt\"}}' | xargs -L 1 bash -c 'echo \$0 \$1'"
alias fixwin="sudo update-binfmts --disable cli"
alias feh="feh --auto-reload"
alias safeupgrade="sudo aptitude safe-upgrade"
alias ansicolors='for i in {0..255}; do  printf "[38;5;${i}mcolor%-5i[0m" $i ; if ! (( ($i + 1 ) % 8 )); then echo ; fi ; done'
alias passc='pass -c'
alias repos='cd $HOME/repos'

# Firebase
alias prettyfire='while read -r line; do if [[ $line =~ "^(> *)?{\"" ]]; then echo -E ${line#">  "} | jq -C ; else echo $line; fi; done'

# dotfile related aliases
alias editutils='vim $HOME/.config/dotfiles/unix/shellutils.sh && source $HOME/.config/dotfiles/unix/shellutils.sh'
alias editenv='vim $HOME/.config/dotfiles/unix/shellenv.sh && source $HOME/.config/dotfiles/unix/shellenv.sh'
alias editvimrc='vim $HOME/.config/nvim/init.lua'
alias dots='cd $HOME/.config/dotfiles'
alias conf='cd $HOME/.config'

# Kubernetes aliases
alias k='kubectl'
alias k3='k3s kubectl'
alias kgp='kubectl get pods'
alias podget='kubectl get pods | fzf | awk "{print \$1}"'
alias svcget='kubectl get svc | fzf | awk "{print \$1}"'
alias podexec='podget | $(gnuify xargs) --open-tty -I{} kubectl -it exec {} --'
alias podsh='podexec sh'
alias podbash='podexec bash'
alias svcexec='svcget | $(gnuify xargs) --open-tty -I{} kubectl -it exec svc/{} --'
alias svcsh='svcexec sh'
alias svcbash='svcexec bash'

# Git aliases
alias pullrepos='for repo in `ls -1`; do printf "Pulling \e[33m$repo\e[0m\n"; git -C $repo pull; done'
alias glol="git log --pretty=format:'%C(yellow)%h %Cred%ad %C(cyan)%an%Cgreen%d %Creset%s' --date=iso"
alias gd='git diff'
alias gdh1='git diff HEAD~1'
alias gdh3='git diff HEAD~3'
alias gdcs='git diff --compact-summary'
alias gl='git log'
alias gri='git rebase -i'
alias gacm='git add . && git commit -m'
alias gp='git pull'
alias fgd="glol --color=always | fzf --ansi --reverse --multi 2 | sort -k 2,3 | awk '{print \$1}' | xargs sh -c 'git diff \$0\$([ ! \$1 ] && echo ~1 || echo \"\") \${1:-\$0}'"
alias fgc='glol --color=always | fzf --ansi --reverse | xargs sh -c "git checkout \$0"'
alias fgcrl='git reflog --color=always | fzf --ansi --reverse | xargs sh -c "git checkout \$0"'
alias gspp='git stash && git pull && git stash pop'
alias cdgr='cd $(git rev-parse --show-toplevel)'
alias fga='git ls-files -m -o --exclude-standard | fzf --print0 -m | xargs -0 -t -o git add'
alias lgit='lazygit'
alias git-delete-squashed='TARGET_BRANCH=${TARGET_BRANCH:-main} && git checkout -q $TARGET_BRANCH && git for-each-ref refs/heads/ "--format=%(refname:short)" | while read branch; do mergeBase=$(git merge-base $TARGET_BRANCH $branch) && [[ $(git cherry $TARGET_BRANCH $(git commit-tree $(git rev-parse $branch\^{tree}) -p $mergeBase -m _)) == "-"* ]] && git branch -D $branch; done'
alias gdots='git -C $HOME/.config/dotfiles'
alias ldots='lazygit -p $HOME/.config/dotfiles'

# Tmux
alias tmuxwork='tmuxp load $HOME/.config/tmuxp/work.yaml'
alias tmuxapato='tmuxp load $HOME/.config/tmuxp/apato.yaml'

# Custom functions
_targetfzf() {
  local command=${1}
  local filetype=${2}
  local searchdir=${3:-$PWD}
  shift 3

  local showAll=0
  while getopts 'a' option; do
    case $option in
      a) showAll=1 ;;
      *)
        echo 'Wrong usage'
        return 1
        ;;
    esac
  done
  shift $(($OPTIND - 1))

  local query=${1:-''}

  if [[ $showAll == 1 ]]; then
    local target=$(find $searchdir -type $filetype | fzf -i -1 -q "$query")
  else
    local target=$(find $searchdir -path "*/.*" -prune -o -type $filetype -print | fzf -i -1 -q "$query")
  fi

  if [[ ! $target ]]; then
    return 0
  fi

  eval "$command \"$target\""
}

gstrim() {
  local changedFiles=($(git diff --name-only --diff-filter=AMC | xargs))
  if [[ ! $changedFiles ]]; then
    echo "No changes detected, will not trim anything"
    return
  fi

  for file in $changedFiles; do
    $(gnuify sed) -i 's/[[:space:]]*$//' $file
    echo "Trimmed $file"
  done
}

rgvim() {
  if [[ $# -lt 1 ]]; then
    echo "No pattern specified"
    echo "Usage: rgvim PATTERN"
    return 1
  fi

  local target=$(rg -uu --vimgrep --color always $1 | fzf --ansi)
  if [[ ! $target ]]; then
    return 0
  fi

  echo $target | tr : ' ' | xargs bash -c 'nvim +$1 $0'
}

readwhich() {
  readlink -f $(which $1)
}

writehook() {
  if [[ $# -lt 2 ]]; then
    echo "insufficient number of arguments"
    echo "usage: writehook fileDirOrRegex task"
    echo "example: writehook '*.txt' 'echo This will run when you save to any .txt file in .'"
    return
  fi
  local whereToWatch=$1
  local onWriteCommand=$2

  local watchCmd
  local watchIn
  local useRegex=0
  if [ -f $whereToWatch ]; then
    watchCmd="echo $whereToWatch | entr -rpzd echo /_"
    watchIn="$whereToWatch"
    useRegex=0
  else
    watchCmd="find . -type d -name node_modules -prune -false -o -type f -regex \"$whereToWatch\" | entr -rpzd echo /_"
    watchIn="."
    useRegex=1
  fi

  local beforeRunMessage="Will watch for changes in \e[32m$watchIn\e[0m"
  if [ $useRegex -eq 1 ]; then
    beforeRunMessage="${beforeRunMessage} for files that matches \e[33m$1\e[0m"
  fi
  echo -e $beforeRunMessage

  while true; do
    target=($(eval $watchCmd))
    if [ ! $? -eq 0 ]; then
      continue
    fi

    echo -e "\e[33mDetected modification in \e[32m$target\e[0m"
    eval "$(echo $onWriteCommand | sed "s|{?}|$target|")"
  done
}

gnuify() {
  # Adapter function for MacOS
  # Attemps to use gnu variants if available
  # Example gnuify sed returns gsed
  #
  # You can install gnu variants through homebrew
  if command -v g$1 > /dev/null; then
    echo g$1
  else
    echo $1
  fi
}

registerforreflection() {
  # Explanation for '0,/PATTERN/! b;//i\TEXT'
  # 0,/PATTTERN/ specifies a range of which sed can do stuff
  # The ending "!" says "not", thus 0,/PATTERN/! selectes everything not in the range
  # The b is an uncoditional branch, which means "don't do anything" when there is nothing else specified
  # The ; is just a delimiter for a script
  # Thus 0,/PATTERN/! b; means for everything not in the range 0,/PATTERN/, don't do anything
  # The //i\TEXT adds the line "TEXT" over whatever was the previous regex (which is the last line in the range)
  for file in $(find . -type f -name "*.java"); do
    name=$(basename $file .java)
    $(gnuify sed) -i -E -e '0,/(class|enum) '$name'/! b;//i\@RegisterForReflection' -e '0,/package/! b;//a\\nimport io.quarkus.runtime.annotations.RegisterForReflection;' $file
  done
}

registerforreflection2() {
  # Explanation for '0,/PATTERN/! b;//i\TEXT'
  # 0,/PATTTERN/ specifies a range of which sed can do stuff
  # The ending "!" says "not", thus 0,/PATTERN/! for everything not in the range
  # The b is an uncoditional branch, which when it is alone it will act as a "don't do anything"
  # The ; is just a delimiter for a script
  # Thus 0,/PATTERN/! b; means for everything not in the range 0,/PATTERN/, don't do anything
  # The //i\TEXT a line "TEXT" over whatever was the previous regex (which is the last line in the range)

  find . -type f -name "*.java" -exec sed -i -e '0,/class $(basename {} .java)/! b;//i\@RegisterForReflection' -e '0,/package/! b;//a\\nimport io.quarkus.runtime.annotations.RegisterForReflection;' {} \;
}

ccat() {
  pygmentize -g -O style=monokai $1 | cat -n
}

jcat() {
  python3 -m json.tool $1 | pygmentize -O style=monokai -l json
}

xcat() {
  xmllint --format - $1 | pygmentize -O style=monokai -l xml
}

daystony() {
  local datecmd=$(gnuify date)
  nydate=$(expr $($datecmd +%Y) + 1)/01/01
  ndays=$(expr '(' $($datecmd -d $nydate +%s) - $($datecmd +%s) + 86399 ')' / 86400)
  echo "Days to new year: $ndays"
}

splitlines() {
  local cumstring=""
  local lines=0

  while IFS= read -r line; do
    ((lines++))
    if [[ -n "$cumstring" ]]; then
      cumstring+=$'\n'
    fi
    cumstring+="$line"
  done

  local middle=$(((lines + 1) / 2))

  echo "$(head -n $middle <<< $cumstring)"
  echo
  echo "$(tail -n +$((middle + 1)) <<< $cumstring)"
}

gitclean() {
  echo "Pruning stale tracking branches"
  git remote prune origin

  todelete=$(git branch -v | awk '$3~/\[gone\]/ {print $1}')
  if [ -z "$todelete" ]; then
    printf "No branches to delete\n"
  else
    printf "Are you sure you want to delete:\n\e[33m$todelete\e[0m\n(y/n): "
    read confirm
    if [[ $confirm == [yY] || $confirm == [yY][eE][sS] ]]; then
      printf "$todelete" | xargs -r git branch -D
    else
      printf "Operation cancelled\n"
    fi
  fi
}
