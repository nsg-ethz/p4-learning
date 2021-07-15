# Simple Stateful Firewall

```

+--+      +--+     ++-+     +--+
|h1+------+s1+-----+s2+-----+h2|
+--+      +-++     +--+     +--+
```

## Introduction

Switch S1 is acting as a stateful firewall, it will only allow connections
to be establish from h1. h2 is only able to reply to connections once they
have been established from h1.

**Note:** This stateful firewall is implemented 100% in the dataplane, meanning that
to check if a connection was established a bloom filter is used. Thus, there
is a probability of having collisions that would let unwanted flows pass. Of course
this is just a toy example for educational purposes.  A more realistic implementation
would require the use of the Control Plane.

### How to run

Start the topology:
```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Inside the mininet CLI run two different iperfs:

From h1 you are able to connect:

```
*** Starting CLI:
mininet> iperf h1 h2
*** Iperf: testing TCP bandwidth between h1 and h2
*** Results: ['49.4 Mbits/sec', '51.2 Mbits/sec']
```

From h2 you are not able:

```
mininet> iperf h2 h1
*** Iperf: testing TCP bandwidth between h2 and h1
...
...
...
```