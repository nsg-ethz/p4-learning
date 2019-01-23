# Multicast

```
+--+      +--+     ++-+
|h1+------+  +-----+h2+
+--+      +  +     +--+
          +s1+
+--+      +  +     ++-+
|h3+------+  +-----+h4+
+--+      +-++     +--+

```

## Introduction

In this example we show how to use the multicasting engine to broadcast
packets to all the ports of the switch.

In this very simple example we create a multicast group that sends packets
to all the four ports. Thus, the packet to broadcast will be sent back to
the port it came in. To avoid that, you can create a multicast group for
each ingress port, and then use it accordingly.

Note: Only packets with an ethernet type of `0x1234` get multicasted
to all the ports.

You can find more information about how to create multicast groups in
the following [documentation section](../../documentation/simple-switch.md#creating-multicast-groups)

## How to run

Run the topology:

```
sudo p4run
```

Send traffic with the special ethernet type using the `send.py` script.

```
mx h1
python send.py
```

Monitor all the interfaces and see that for each packet that is sent from `h1`
four packets get replicated.
