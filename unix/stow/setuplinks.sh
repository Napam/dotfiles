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

stow -d . -t "$HOME" --dotfiles -v 2 */
