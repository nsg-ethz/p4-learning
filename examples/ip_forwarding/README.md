# Implementing Basic Forwarding

```
                   +--+
                   |h4|
                   ++-+
                    |
                    |
+--+      +--+     ++-+     +--+
|h1+------+s1+-----+s3+-----+h3|
+--+      +-++     +--+     +--+
            |
            |
          +-++
          |s2|
          +-++
            |
            |
          +-++
          |h2|
          +--+
```

## Introduction

The objective of this exercise is to write a P4 program that
implements basic forwarding. To keep things simple, we will just
implement forwarding for IPv4.

With IPv4 forwarding, the switch must perform the following actions
for every packet: (i) update the source and destination MAC addresses,
(ii) decrement the time-to-live (TTL) in the IP header, and (iii)
forward the packet out the appropriate port.

Your switch will have a single table, which the control plane will
populate with static rules. Each rule will map an IP address to the
MAC address and output port for the next hop. We have already defined
the control plane rules, so you only need to implement the data plane
logic of your P4 program.


# Parser

The parser describes a state machine with one `start` state and two possible final states: `accept`
or `reject`. Explain the basic state machine used to parse ethernet and ipv4, and explain that this
can be used later to access those headers fields.