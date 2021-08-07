#!/usr/bin/env bash
<<<<<<< HEAD

# Ping among each pair of hosts
=======
>>>>>>> 4b095f3b830dcd75e18ca19ed6b123be6e17075d
sudo ip netns exec h1 ping 1.0.2.2 -c 1
sudo ip netns exec h1 ping 1.0.3.2 -c 1
sudo ip netns exec h2 ping 1.0.1.2 -c 1
sudo ip netns exec h2 ping 1.0.3.2 -c 1
sudo ip netns exec h3 ping 1.0.1.2 -c 1
sudo ip netns exec h3 ping 1.0.2.2 -c 1
