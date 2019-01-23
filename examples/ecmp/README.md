# Equal-Cost Multi-Path Routing
```
                 
                          +--+
             +------------+s2+------------+
             |            +--+            |
             |                            |
             |                            |
             |            +--+            |
             |        +---+s3+----+       |
          +--+--+     |   +--+    |    +--+--+
+--+      |     +-----+           +----+     |     +--+
|h1+------+ s1  |                      | s6  +-----+h2|
+--+      |     +-----+           +----+     |     +--+
          +--+--+     |   +--+    |    +--+--+
             |        +---+s4+----+       |
             |            +--+            |
             |                            |
             |                            |
             |            +--+            |
             +------------+s5+------------+
                          +--+


         
```

## Introduction

In this example  we  implement a layer 3 forwarding switch that is able to load balance traffic
towards a destination across equal cost paths. To load balance traffic across multiple ports we will implement ECMP (Equal-Cost
Multi-Path) routing. When a packet with multiple candidate paths arrives, our switch should assign the next-hop by hashing some fields from the
header and compute this hash value modulo the number of possible equal paths. For example in the topology above, when `s1` has to send
a packet to `h2`, the switch should determine the output port by computing: `hash(some-header-fields) mod 4`. To prevent out of order packets, ECMP hashing is done on a per-flow basis,
which means that all packets with the same source and destination IP addresses and the same source and destination
ports always hash to the same next hop.

## How to run

Run the topology:

```
sudo p4run
```


Monitor all the interfaces connecting `s1` to the 4 middle switches. You can use `tshark`, `tcpdump`:

```
sudo tshark -i s1-eth2
```

(Do the same with the other three interfaces).

Send packets with random ports from `h1`:

```
mx h1
python send.py 10.0.6.2 1000
```