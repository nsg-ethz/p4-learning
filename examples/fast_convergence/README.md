# Fast convergence

```


                   +--+
            +------+s2+------+
            |      +--+      |
+--+      +-++              ++-+       +------------------+
|h1+------+s1|              |s4+-------+h2/h3/50k prefixes|
+--+      +-++              ++-+       +------------------+
            |                |
            |      +--+      |
            +------+s3+------+
                   +--+


```
## Description

In this simple example, we have three hosts:
- `h1` with IP `10.0.1.1/24` connected to the switch `s1`,
- `h2` with IP `10.0.2.1/24` connected to the switch `s2`,
- `h3` with IP `10.250.250.1/24` connected to the switch `s2`.

In addition to these, there are 50000 more prefixes that are connected to `s4` and for which the switches need to take a routing decision based on a forwarding rule. **Notice**: these extra IPs are not bound to a real node (indeed switch `s4` drops packets destined to these addresses) and are there only to give an idea of the actual amount of prefixes that a router in the Internet has to deal with.

The same topology will be executed with two different approaches:
- with a plain forwarding table (as defined by `forwarding_one_table.p4`) binding each address to an outbound port of the device,
- with two hierarchical forwarding tables (as defined by `forwarding_two_tables.p4`), the fist one binding each IP to an index of the second table and the second one relating such index to an outbound port.

One can easily see that two different routes are available from packets from `h1` to `h2`/`h3`/`50k prefixes`:
1. via `s1-s2-s4`,
2. via `s1-s3-s4`.

By default choice, switch `s1` will forward packets using 1. So, if a failure happend on links `s1-s2` or `s2-s4` the traffic has to be rerouted through 2. This process requires some time to complete. The goal of this example is assessing which one of the approaches described before is the most time efficient.

## How to run

### One table approach

Run the topology and populate (for the first time) the forwarding table of `s1` with this command. **Notice**: the process takes some time. Use one of the following commands:
```bash
sudo p4run --config p4app_one_table.json
```

or
```bash
sudo python network_one_table.py
```

Verify that there is connectivity among hosts:
```
mininet> pingall
```

Simultaneously ping `h2` and `h3`:
```bash
mx h1
ping 10.0.2.2

# Another terminal
mx h1
ping 10.250.250.2
```

Fail the link between `s1` and `s2`:
```
mininet> link s1 s2 down
```

The ping requests will stop arriving at the destination because of the failure. To restore the connectivity, run the following in a new terminal:
```bash
sudo python controller_one_table.py reroute 50000
```

This script will update all the entries of the forwarding table of `s1` making `h2` and `h3` reachable again (e.g. using ping). It is interesting to notice that `h2` and `h3` are reachable again at different times (the entry of `h2` is updated before that of `h3`). The scripts also computes the updating time and shows it.

### Two tables approach

Run the topology and populate (for the first time) the forwarding table of `s1` with this command. **Notice**: the process takes some time. Use one of the following commands:
```bash
sudo p4run --config p4app_two_tables.json
```

or
```bash
sudo python network_two_tables.py
```

Verify that there is connectivity among hosts:
```
mininet> pingall
```

Simultaneously ping `h2` and `h3`:
```bash
mx h1
ping 10.0.2.2

# Another terminal
mx h1
ping 10.250.250.2
```

Fail the link between `s1` and `s2`:
```
mininet> link s1 s2 down
```

The ping requests will stop arriving at the destination because of the failure. To restore the connectivity, run the following in a new terminal:
```bash
sudo python controller_two_tables.py reroute 50000
```

This script will update all the entries of the forwarding table of `s1` making `h2` and `h3` reachable again (e.g. using ping). It is interesting to notice that now `h2` and `h3` are reachable again at the same time. The scripts also computes the updating time and shows it.

## Results

One can easily notice that the hierarchical forwarding tables are more time efficient than the plain forwarding table. Moreover, the updating time of the hierarchical forwarding tables does not depend on the number of entries contained in the FIB, whereas the updating time required by the plain forwarding table is linearly dependent on such number.
