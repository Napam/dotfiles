#!/usr/bin/env sh
#shellcheck shell=bash disable=SC2035

mkdir -p "$HOME/.local"
mkdir -p "$HOME/.config"

stow -d . -t "$HOME" --dotfiles -v 2 */
