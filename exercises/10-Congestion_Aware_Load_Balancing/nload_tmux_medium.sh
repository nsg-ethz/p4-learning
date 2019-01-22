#!/usr/bin/env bash

tmux split-window -h
tmux select-pane -t 0
tmux split-window -v

tmux select-pane -t 2
tmux split-window -v


tmux select-pane -t 0
tmux send "nload s1-eth1" ENTER

tmux select-pane -t 1
tmux send "nload s1-eth3" ENTER

tmux select-pane -t 2
tmux send "nload s1-eth2" ENTER

tmux select-pane -t 3
tmux send "nload s1-eth4" ENTER

