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

   CYGWIN*|MINGW*|MINGW32*|MSYS*)
     IS_WINDOWS=1
     ;;
esac

#X11 stuff
#export DISPLAY=$(awk '/nameserver / {print $2; exit}' /etc/resolv.conf 2>/dev/null):0
#export DISPLAY=:0
#export LIBGL_ALWAYS_INDIRECT=1

# Programs in home local bin
export PATH="$PATH:$HOME/.local/bin"

# GCC
export LD_LIBRARY_PATH="/lib:/usr/lib:/usr/local/lib"

# GO
export GOPATH="$HOME/.go"
export PATH="$PATH:$GOROOT:$GOPATH/bin"

#Virtualenvwrapper settings:
# export WORKON_HOME=$HOME/.virtualenvs
# VIRTUALENVWRAPPER_PYTHON=/usr/bin/python3
# source $HOME/.local/bin/virtualenvwrapper.sh

# Use LunarVim instead
alias vim=lvim

export EDITOR=vim

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# yarn bin to path
export PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

if [[ -v IS_MAC ]]; then
  export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"
else
  export JAVA_HOME="/usr/lib/jvm/java-1.17.0-openjdk-amd64"
fi
#export JAVA_TOOL_OPTIONS="-Djava.net.preferIPv4Stack=true"

# Add JBang to environment
alias j!=jbang
export PATH="$HOME/.jbang/bin:$PATH"

# Rust cargo
source "$HOME/.cargo/env"

# venvy
export VENVY_SRC_DIR="$HOME/.local/src/venvy"
[[ -s $VENVY_SRC_DIR ]] && source "$VENVY_SRC_DIR/venvy.sh"

# kubectl editor
export KUBE_EDITOR=lvim

export GREP_COLORS='ms=01;31:mc=01;31:sl=:cx=:fn=36:ln=32:bn=32:se=33'

if command -v tmux &> /dev/null && [ -n "$PS1" ] && [[ ! "$TERM" =~ screen ]] && [[ ! "$TERM" =~ tmux ]] && [ -z "$TMUX" ]; then
  exec tmux
fi

