#!/usr/bin/env bash

# Ping among each pair of hosts
sudo ip netns exec h1 ping 1.0.2.2 -c 1
sudo ip netns exec h1 ping 1.0.3.2 -c 1
sudo ip netns exec h2 ping 1.0.1.2 -c 1
sudo ip netns exec h2 ping 1.0.3.2 -c 1
sudo ip netns exec h3 ping 1.0.1.2 -c 1
sudo ip netns exec h3 ping 1.0.2.2 -c 1
