#!/usr/bin/env sh

mkdir -p $HOME/.local
mkdir -p $HOME/.config

stow -d . -t $HOME --dotfiles -v 2 */
