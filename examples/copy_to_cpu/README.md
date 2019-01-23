# Copy To Cpu

```
+--+      +--+     ++-+
|h1+------+s1+-----+h2+
+--+      +-++     +--+

```

## Introduction

In this example we show how to send a copy of a packet to any port. However, in this very specific case we send it to a special port
called `cpu_port`. The `cpu_port` is the port that connects the switch with an external controller. The `extern` clone egress
to egress is used to send a copy of the egress packet to the buffer mechanism located between the ingress and egress
pipeline.

In this simple program packets with IPv4 TOS field equal to 1 are sent to the cpu port (`s1-cpu-eth1`). You can use `send.py` to send packets with the tos field modified. And
`receive.py` to receive the cpu packets. In addition to sending packets to the controller, this example shows how to add custom headers
to a packet.

**Note:** that to add an extra port to each switch we added the attribute
`cpu_port` to the `p4app.json` file.

## How to run

Run the topology:

```
sudo p4run
```

Run the very small controller code that receives packets from the switch:

```
sudo python receive.py
```

Generate packets using the `send.py` script which sets the TOS field to 1.

```
mx h1
sudo python send.py 10.0.1.2
```
