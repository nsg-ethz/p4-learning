#!/usr/bin/env bash

# Kill routers
sudo pkill -f "zebra"
sudo pkill -f "ospfd"
sudo pkill -f "tcpdump"

# Clean commands
sudo ip netns del h1
sudo ip netns del h2
sudo ip netns del h3
sudo ip netns del r1
sudo ip netns del r2
sudo ip netns del r3

# Clean temporary files
sudo rm /tmp/*.out /tmp/*.log /tmp/*.pid