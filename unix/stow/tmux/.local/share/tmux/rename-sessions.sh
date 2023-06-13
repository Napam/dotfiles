#!/bin/bash

tmux ls | awk '{print +$1,NR}' | xargs -L 1 sh -c 'tmux rename -t $0 $1'
