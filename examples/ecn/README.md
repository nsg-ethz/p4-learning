# Explicit Congestion Notification

```

+--+      +--+     ++-+
|h1+------+s1+-----+h3+
+--+      +-++     +--+
            |
            |
          +-++
          |h2|
          +-++

```

## Introduction

The link between `s1` and `h3` has a bandwidth of 0.5 Mbps and acts as a bottleneck for the traffic coming from the other hosts towards `h3`. If Explicit Congestion Notification is enabled for traffic going through the switch (`ECN` field of the IPv4 packet, i.e. the two least significant bits of the `TOS` field, must be set to `1` or `2`) If the output queue builds up, the P4 switch will tag packets with the ECN flag `3`.

## How to run

Run the topology:

```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Monitor the traffic going from `s1` to `h3`.
```bash
sudo tcpdump -i s1-eth3 -Q out -v
```

Then generate a UDP flow (or multiple) from `h1` towards `h3`.
```
mininet> task h1 0 0 recv_udp_flow --dport 5051
mininet> task h1 0 30 send_udp_flow --dst 10.1.3.2 --sport 5000 --dport 5051 --tos 1 --rate 10M
```

Observe that when congestion is built packet will start to have the ECN flag set to `3`.

