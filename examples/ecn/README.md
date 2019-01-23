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

If the output queue builds up, the P4 switch will tag packets with the ECN flag "11".

## How to run

Run the topology:

```
sudo p4run
```

Use tshark, wireshark or another monitoring tool that allows you to inspect the TOS field value, specially
the first 2 bits.

Then generate a TCP flow (or multiple) towards `h3`. And observe that when congestion
is built packet will start to have the ECN flag set to `11`.

