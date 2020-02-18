#!/usr/bin/env bash

mx h2 iperf -s -p 5000 &
mx h3 iperf -s -p 5000 &

sleep 2

mx h1 iperf -c 10.0.2.2 -p 5000 -t 3000 -i 1 &
mx h1 iperf -c 10.250.250.2 -p 5000 -t 3000 -i 1 &
