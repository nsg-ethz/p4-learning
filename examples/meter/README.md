# Meter

```
+--+      +--+     ++-+
|h1+------+s1+-----+h2+
+--+      +-++     +--+

```


## Introduction

This program illustrates as simply as possible how to use meters in P4 with
bmv2. bmv2 uses two-rate three-color meters as described
[here](https://tools.ietf.org/html/rfc2698).

For each incoming packet the `m_read` table is applied and the appropriate
meter (based on the packet's source MAC address) is executed. Based on the
observed traffic rate for this sender and the meter's configuration, executing
the meter will yield one of 3 values: `0` (*GREEN*), `1` (*YELLOW*) or `2`
(*RED*). This value will be copied to metadata field `meta.meter_tag`. Note that
if no meter was associated to the sender's MAC address, the table will be a
no-op. This table also redirects all packets - with a known source MAC address-
to port 2 of the switch.

After that, the packet will go through a second table, `m_filter`, which can
either be a no-op or drop the packet based on how the packet was tagged by the
meter. 

Note, that we provide the same example with direct and indirect meters. Direct
meters are meters associated to table entries, while indirect meters can be
addressed by index. You can have a look at both source codes to see the
difference. 

If you take a look at the source code for [indirect
counter](indirect_meter.p4#L94) you can see that we set the default action to
drop. Also, if you take a look at the [control plane
commands](indirect_commands.txt) you can see (line 2) how we set a rule for
`meta.meter_tag == 0`. Thus, all packets  for which `meta.meter_tag` is not `0`
will be dropped.

The [control plane command](indirect_commands.txt) file also gives you the meter
configuration. In this case, the first rate is 0.5 packets per second, with a
burst size of 1, and the second rate is 10 packets per second, with a burst size
of 1 also. Feel free to play with the numbers, but these play nicely with the
demonstration below.

## How to run

There are two examples, one using a direct and one using an indirect meter.
You can start them using:
```bash
sudo p4run --config p4app_direct.json
sudo p4run --config p4app_indirect.json
```

or
```bash
sudo python network_direct.py
sudo python network_indirect.py
```

In the mininet CLI, you can start the demo script which periodically
sends packets from the host 1 interface and listens for packets on the host 2
interface. The script takes the time interface (in seconds) as argument, e.g.:
```bash
mininet> sh ./send_and_receive.py 1
```

(Works for both direct and indirect meters)

If you run the script with an interval of one second, you should observe the
following output:
```bash
Received one
Sent one
Sent one
Received one
Sent one
Sent one
Received one
Sent one
...
```

This is because we send one packet every second, while the first rate of the
meter is 0.5 packets per second. The P4 program therefore drops on average one
packet out of two.

If you run the script with in interval of two seconds, you will notice that
no packet gets dropped anymore.
