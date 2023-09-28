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

# Use LunarVim instead
alias vim=nvim
export EDITOR=nvim
export GIT_EDITOR=nvim

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"                   # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# yarn bin to path
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if [[ -v IS_MAC ]]; then
	export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-20.jdk/Contents/Home"
else
	export JAVA_HOME="/usr/lib/jvm/java-1.17.0-openjdk-amd64"
fi
#export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# Rust cargo
if [[ -s $HOME/.cargo/env ]]; then
	source "$HOME/.cargo/env"
fi

# pnpm
if [[ $IS_MAC ]]; then
	export PNPM_HOME="/Users/naphat/Library/pnpm"
	case ":$PATH:" in
	*":$PNPM_HOME:"*) ;;
	*) export PATH="$PNPM_HOME:$PATH" ;;
	esac
fi

# Flutter
if [[ -s /opt/flutter ]]; then
	export PATH="$PATH:/opt/flutter/bin"
fi

# venvy
export VENVY_SRC_DIR="$HOME/.local/src/venvy"
[[ -s $VENVY_SRC_DIR ]] && source "$VENVY_SRC_DIR/venvy.sh"

if command -v pass &>/dev/null; then
	source "$HOME/.config/dotfiles/unix/pass-completion.zsh"
fi

# kubectl editor
export KUBE_EDITOR=nvim

export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=36:ln=32:bn=32:se=33'

if [[ $ZSH_VERSION ]]; then
	[[ -e $HOME/.zsh-vi-mode ]] && source $HOME/.zsh-vi-mode/zsh-vi-mode.plugin.zsh
fi

if command -v tmux &>/dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
	exec tmux
fi
