# shellcheck shell=bash disable=SC1090,SC1091,SC2034
# Shared interactive shell plumbing. Sourced by dot-bashrc and dot-zshrc AFTER
# they set $_RC_SHELL to "bash" or "zsh".

if [[ -z ${_RC_SHELL-} ]]; then
  echo "shellrc.sh: _RC_SHELL must be set to 'bash' or 'zsh' before sourcing" >&2
  # shellcheck disable=SC2317  # exit reached when script is executed, not sourced
  return 1 2> /dev/null || exit 1
fi

[[ -s "$HOME/.localrc" ]] && source "$HOME/.localrc"

source "$HOME/.config/dotfiles/unix/shellenv.sh"
source "$HOME/.config/dotfiles/unix/shellutils.sh"

# WARN: don't rely on PATH alone — Mac bash non-login skips brew's .zprofile injection.
# Probe known install locations as fallback.
init_mise() {
  [[ -n ${_mise_activated-} ]] && return 0

  local bin
  bin=$(command -v mise)
  if [[ -z $bin ]]; then
    for c in "$HOME/.local/bin/mise" /opt/homebrew/bin/mise /usr/local/bin/mise; do
      if [[ -x $c ]]; then
        bin=$c
        break
      fi
    done
  fi

  [[ -n $bin ]] || return 1
  eval "$("$bin" activate "$_RC_SHELL")"
  _mise_activated=1
}

git_current_branch() {
  local ref ret
  ref=$(git symbolic-ref --quiet HEAD 2> /dev/null)
  ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return 1
    ref=$(git rev-parse --short HEAD 2> /dev/null) || return 1
  fi
  echo "${ref#refs/heads/}"
}

git_is_dirty() {
  [[ -n $(git status --porcelain 2> /dev/null) ]]
}

# Returns env category: prod / nonprod / other / (empty if ENV unset/empty)
prompt_env_category() {
  [[ -n ${ENV-} ]] || return
  case $ENV in
    *prod* | *live*)                 echo prod ;;
    *dev* | *test* | *stage* | *qa*) echo nonprod ;;
    *)                               echo other ;;
  esac
}

# Tools whose `<tool> completion <shell>` output is sourceable in both bash and zsh.
_load_eval_completions() {
  command -v kubectl &> /dev/null && source <(kubectl completion "$_RC_SHELL")
  command -v k3d     &> /dev/null && source <(k3d     completion "$_RC_SHELL")
  command -v just    &> /dev/null && source <(just --completions   "$_RC_SHELL")
  command -v fzf     &> /dev/null && eval "$(fzf --"$_RC_SHELL")"
  command -v zoxide  &> /dev/null && eval "$(zoxide init "$_RC_SHELL")"
  [[ -n ${VENVY_SRC_DIR-} && -d $VENVY_SRC_DIR ]] && source "$VENVY_SRC_DIR/completions/init.sh"
  # NVM completion is bash-syntax — only safe in bash (zsh would need bashcompinit first).
  [[ $_RC_SHELL == bash && -s "$NVM_DIR/bash_completion" ]] && source "$NVM_DIR/bash_completion"
}

init_epilogue() {
  command -v direnv &> /dev/null && eval "$(direnv hook "$_RC_SHELL")"
  [[ -f "$HOME/.config/dotfiles-private/unix/init.sh" ]] && source "$HOME/.config/dotfiles-private/unix/init.sh"
  [[ -f "$HOME/.config/dotfiles-work/unix/init.sh" ]] && source "$HOME/.config/dotfiles-work/unix/init.sh"
  command -v _localrc_after &> /dev/null && _localrc_after
}

# Sources kube-ps1 and sets shared config. Returns 0 if loaded (caller should
# update PROMPT to include $(kube_ps1)). PREFIX/SUFFIX/DIVIDER use shell-specific
# escape syntax — bash needs raw \001\002 readline markers, zsh uses %F{}.
init_kube_ps1() {
  local src="$HOME/.local/src/kube-ps1/kube-ps1.sh"
  [[ -f $src ]] || return 1
  source "$src"
  local color=154
  case ${_RC_SHELL:-} in
    bash)
      KUBE_PS1_PREFIX=$'\001\e[38;5;'"${color}"$'m\002['
      KUBE_PS1_SUFFIX=$'\001\e[38;5;'"${color}"$'m\002]\001\e[0m\002'
      KUBE_PS1_DIVIDER=$'\001\e[38;5;'"${color}"$'m\002|'
      ;;
    zsh)
      KUBE_PS1_PREFIX="%F{${color}}["
      KUBE_PS1_SUFFIX="%F{${color}}]%f"
      KUBE_PS1_DIVIDER="%F{${color}}|"
      ;;
  esac
  KUBE_PS1_CTX_COLOR=$color
  KUBE_PS1_NS_COLOR=$color
  KUBE_PS1_SYMBOL_ENABLE='false'
  KUBE_PS1_NS_ENABLE='true'
}

# WARN: must run AFTER init_epilogue. Previously lived in shellenv.sh where
# `exec tmux` pre-empted direnv/kube-ps1/private-init/_localrc_after.
maybe_exec_tmux() {
  command -v tmux > /dev/null 2>&1 || return
  case $- in *i*) ;; *) return ;; esac
  case ${TERM-} in screen* | tmux*) return ;; esac
  [[ -z ${TMUX-} ]] || return
  [[ ${LOCAL_TMUX-} == true ]] || return
  exec tmux
}
