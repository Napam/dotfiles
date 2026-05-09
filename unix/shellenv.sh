# shellcheck shell=bash disable=SC1090,SC1091
# Sourced from interactive rc files. Must be safe for repeated sourcing.
# No prompts, no exec, no interactive-only constructs (those live in shellrc.sh / rc files).

case "$(uname -s)" in
  Darwin) export IS_MAC=1 ;;
  Linux)
    if [[ -f /proc/sys/fs/binfmt_misc/WSLInterop ||
          -f /proc/sys/fs/binfmt_misc/WSLInterop-late ||
          $(uname -r) =~ (microsoft|WSL2) ]]; then
      export IS_WSL=1
    else
      export IS_LINUX=1
    fi
       ;;
esac

# WARN: must run before anything else that probes brew bins (must be early)
if [[ ${IS_MAC-} ]] && [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

if [[ ${IS_MAC-} ]]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

if [[ $ZSH_VERSION ]]; then
  export HISTFILE="$HOME/.zsh_history"
  export HISTSIZE=240000
  export SAVEHIST=$HISTSIZE

  export CLICOLOR=1
  export LSCOLORS=gxFxCxDxBxegedabagaced
  export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
elif [[ $BASH_VERSION ]]; then
  HISTSIZE=240000
  HISTFILESIZE=240000
  HISTCONTROL=ignoreboth
fi

# WARN: brew shellenv above already prepends /opt/homebrew/bin; the helper below is the Linux fallback.
path_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1:$PATH" ;; esac  }
path_append()  { case ":$PATH:" in *":$1:"*) ;; *) PATH="$PATH:$1" ;; esac  }

[[ -d /opt/homebrew/bin ]] && path_prepend /opt/homebrew/bin
# bob-managed nvim — must precede brew/usr nvim
[[ -d "$HOME/.local/share/bob/nvim-bin" ]] && path_prepend "$HOME/.local/share/bob/nvim-bin"
[[ -d /snap/bin ]] && path_prepend /snap/bin
path_append "$HOME/.local/bin"

export GOPATH="$HOME/.go"
[[ -d $GOPATH/bin ]] && path_append "$GOPATH/bin"

export BUN_BIN="$HOME/.bun/bin"
[[ -d $BUN_BIN ]] && path_prepend "$BUN_BIN"

[[ -d "$HOME/.jbang/bin" ]] && path_prepend "$HOME/.jbang/bin"

path_prepend "$HOME/.yarn/bin"
path_prepend "$HOME/.config/yarn/global/node_modules/.bin"

if [[ ${IS_MAC-} ]]; then
  export PNPM_HOME="$HOME/Library/pnpm"
  path_prepend "$PNPM_HOME"
fi

export PATH

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# JAVA_HOME managed by mise (see shellrc.sh: mise activate).
export JAVA_TOOL_OPTIONS="-Djdk.xml.totalEntitySizeLimit=0 -Djdk.xml.entityExpansionLimit=0"

[[ -s $HOME/.cargo/env ]] && source "$HOME/.cargo/env"

export VENVY_SRC_DIR="$HOME/.local/src/venvy"
[[ -f $VENVY_SRC_DIR/venvy.sh ]] && source "$VENVY_SRC_DIR/venvy.sh"

export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=36:ln=32:bn=32:se=33'

# tmuxp tells me to
export DISABLE_AUTO_TITLE='true'

export SCREENDIR="$HOME/.screen"
# WARN: SC2174 — separate mkdir + chmod because `-m` with `-p` only applies to deepest dir
[[ -d $SCREENDIR ]] || { mkdir -p "$SCREENDIR" && chmod 700 "$SCREENDIR"; }
