#!/usr/bin/env bash

#
sudo pkill -f "simple_switch"

# Clean commands
sudo ip netns del h1
sudo ip netns del h2

#remove switches interfaces from root namespace
sudo ip link del s1-eth0
sudo ip link del s1-eth1
sudo ip link del s2-eth0
sudo ip link del s2-eth1