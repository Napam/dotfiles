#!/usr/bin/env sh
#shellcheck shell=bash disable=SC2035

# Important to premake these dirs such that
# stow doesn't link things such as .local,
# or else we get a bunch of stuff in the dotfiles repo.

mkdir -p "$HOME/.local/share"
mkdir -p "$HOME/.local/state"
mkdir -p "$HOME/.local/src"
mkdir -p "$HOME/.local/bin"
mkdir -p "$HOME/.config"
mkdir -p "$HOME/.claude"

if [[ ! -f "$HOME/.claude/settings.local.json" ]]; then
  echo '{"model": "sonnet"}' > "$HOME/.claude/settings.local.json"
fi

stow -d . -t "$HOME" --dotfiles -v 2 */
