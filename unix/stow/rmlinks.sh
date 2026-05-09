#!/usr/bin/env sh
#shellcheck shell=bash disable=SC2035

stow -d . -t "$HOME" --dotfiles -v 2 -D */
