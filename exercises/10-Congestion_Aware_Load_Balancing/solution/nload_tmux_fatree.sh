#!/usr/bin/env bash

tmux split-window -h
tmux select-pane -t 0
tmux split-window -v

tmux select-pane -t 2
tmux split-window -v

tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 0
tmux split-window -h
tmux select-pane -t 2
tmux split-window -h

tmux select-pane -t 4
tmux split-window -v
tmux select-pane -t 4
tmux split-window -h
tmux select-pane -t 6
tmux split-window -h

tmux select-pane -t 8
tmux split-window -v
tmux select-pane -t 8
tmux split-window -h
tmux select-pane -t 10
tmux split-window -h

tmux select-pane -t 12
tmux split-window -v
tmux select-pane -t 12
tmux split-window -h
tmux select-pane -t 14
tmux split-window -h

tmux select-pane -t 0
tmux send "nload s1-eth1" ENTER

tmux select-pane -t 1
tmux send "nload s1-eth2" ENTER

tmux select-pane -t 2
tmux send "nload s2-eth1" ENTER

tmux select-pane -t 3
tmux send "nload s2-eth2" ENTER

tmux select-pane -t 4
tmux send "nload s3-eth1" ENTER

tmux select-pane -t 5
tmux send "nload s3-eth2" ENTER

tmux select-pane -t 6
tmux send "nload s4-eth1" ENTER

tmux select-pane -t 7
tmux send "nload s4-eth2" ENTER

tmux select-pane -t 8
tmux send "nload s5-eth1" ENTER

tmux select-pane -t 9
tmux send "nload s5-eth2" ENTER

tmux select-pane -t 10
tmux send "nload s6-eth1" ENTER

tmux select-pane -t 11
tmux send "nload s6-eth2" ENTER

tmux select-pane -t 12
tmux send "nload s7-eth1" ENTER

tmux select-pane -t 13
tmux send "nload s7-eth2" ENTER

tmux select-pane -t 14
tmux send "nload s8-eth1" ENTER

tmux select-pane -t 15
tmux send "nload s8-eth2" ENTER

