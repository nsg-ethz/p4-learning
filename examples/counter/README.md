# Counter

```
+--+      +--+     ++-+
|h1+------+  +-----+h2+
+--+      +  +     +--+
          +s1+
+--+      +  +     ++-+
|h3+------+  +-----+h4+
+--+      +-++     +--+

```

Simple example of direct and indirect counters that count the packets and bytes arriving at each ingress port.


## How to run

Run the topology, by starting either the direct or indirect examples:

```
sudo p4run --config p4app_direct.json
```
```
sudo p4run --config p4app_indirect.json
```


### Testing the counters

Use e.g. `ping` to send packets. The switch will count all packets and then drop them (because forwarding is not implemented).

Access counter values (for direct and indirect counters):

    $ simple_switch_CLI --thrift-port 9090
    $ RuntimeCmd: counter_read MyIngress.port_counter 0

(where the 1 is the entry handle for a given table entry. For example the first
entry added in a table will have a handle of 0)

### Using a simple control plane to read the counters

The following controller program will establish a connection with the switch
and through a thrift API it will read all the counter values.

```
$ python read_counters.py [direct/indirect]
```


