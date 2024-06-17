case "$(uname -sr)" in
  Darwin*)
    IS_MAC=1
    ;;

  Linux*Microsoft*)
    IS_WSL=1
    ;;

  Linux*)
    IS_LINUX=1
    ;;

  CYGWIN* | MINGW* | MINGW32* | MSYS*)
    IS_WINDOWS=1
    ;;
esac

if [[ $ZSH_VERSION ]]; then
  export HISTFILE="$HOME/.zsh_history"
  export HISTSIZE=240000
  export SAVEHIST=$HISTSIZE

  export CLICOLOR=1
  export LSCOLORS=gxFxCxDxBxegedabagaced
  export LS_COLORS='di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
fi

# Homebrew bin, should be in front of PATH such that brew install binaries comes before usr/bin stuff
if [[ -e /opt/homebrew/bin ]]; then
  export PATH="/opt/homebrew/bin:$PATH"
fi

# Programs in home local bin
export PATH="$PATH:$HOME/.local/bin"

# GCC
export LD_LIBRARY_PATH="/lib:/usr/lib:/usr/local/lib"

# GO
export GOPATH="$HOME/.go"
if [[ -e $GOPATH ]]; then
  export PATH=$PATH:$GOPATH
fi

# Use nvim instead
alias vim=nvim
export EDITOR=nvim
export GIT_EDITOR=nvim

export NVM_DIR="$HOME/.nvm"
[[ -s "$NVM_DIR/nvm.sh" ]] && source "$NVM_DIR/nvm.sh"

# yarn bin to path
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if [[ -v IS_MAC ]]; then
  export JAVA_HOME="/opt/homebrew/Cellar/openjdk/21/libexec/openjdk.jdk/Contents/Home"
else
  export JAVA_HOME="/usr/lib/jvm/java-1.17.0-openjdk-amd64"
fi
#export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# Rust cargo
[[ -s $HOME/.cargo/env ]] && source "$HOME/.cargo/env"

# pnpm
if [[ $IS_MAC ]]; then
  export PNPM_HOME="/Users/naphat/Library/pnpm"
  case ":$PATH:" in
    *":$PNPM_HOME:"*) ;;
    *) export PATH="$PNPM_HOME:$PATH" ;;
  esac
fi

# Flutter and Dart (Flutter includes Dart)
[[ -s /opt/flutter ]] && export PATH="$PATH:/opt/flutter/bin"

# venvy
export VENVY_SRC_DIR="$HOME/.local/src/venvy"
[[ -s $VENVY_SRC_DIR ]] && source "$VENVY_SRC_DIR/venvy.sh"

# kubectl editor
export KUBE_EDITOR=nvim

export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=36:ln=32:bn=32:se=33'

# zsh-vi-mode
if [[ $ZSH_VERSION ]]; then
  [[ -e $HOME/.zsh-vi-mode ]] && source $HOME/.zsh-vi-mode/zsh-vi-mode.zsh
fi

if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi
