#!/usr/bin/env sh

mkdir -p .local
mkdir -p .config

stow -d . -t $HOME --dotfiles -v 2 */
