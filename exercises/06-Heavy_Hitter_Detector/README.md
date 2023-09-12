# Heavy Hitter Detection

## Introduction

<p align="center">
<img src="images/heavy_hitter_topo.png" title="Small Topology"/>
<p/>

In today's first exercise we will play with probabilistic data structures. First we will implement very simple heavy hitter detector
using a counting bloom filter.
Heavy hitters can simply be defined as the traffic sources who send unusually large traffic.
This can be categorized solely by source IP address or can be classified to each application,
or application session that sends the traffic. As you have seen in the lecture, to implement a bloom filter
we need registers and hash functions (to get indexes to the register). The counting bloom filter will allow us to perform heavy hitter
detection on `tcp` flows without using any controller.

The main idea behind a counting bloom filter is to compute multiple hashes of some header values (flow's 5-tuple) and increment the corresponding
indexes in the register structure. We can then check if a flow is in a bloom filter by checking if all the values are above a threshold. As explained
during the lecture, this method can suffer from hash collisions when there are too many heavy hitters for the filter to track. In this exercise we
will not create too many connections, so it should not be a problem.

## Before Starting

Before you start this exercise, update `p4-utils`:

```bash
cd ~/p4-tools/p4-utils
git pull
```

As usual, we provide you with the following files:

- `p4app.json`: describes the topology we want to create with the help of mininet and p4-utils package.
- `network.py`: a Python scripts that initializes the topology using *Mininet* and *P4-Utils*. One can use indifferently `network.py` or `p4app.json` to start the network.
- `heavy_hitter.p4`: p4 program skeleton to use as a starting point.
- `send.py` and `receive.py`: small python scripts to test the solution

#### Notes about p4app.json

For this exercise we will use a the `mixed` IP assignment strategy. If you have a look at `p4app.json` you will see that the option is set to `mixed`. Therefore, only hosts connected to the same switch will be assigned to the same subnet. Hosts connected to a different switch will belong to a different `/24` subnet. If you use the namings `hY` and `sX` (e.g h1, h2, s1...), the IP assignment goes as follows: `10.x.x.y`. Where `x` is the switch id (upper and lower bytes), and `y` is the host id. For example, in the topology above, `h1` gets `10.0.1.1` and `h2` gets `10.0.2.2`.

 
You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://nsg-ethz.github.io/p4-utils/usage.html#json). Also, you can find information about assignment strategies [here](https://nsg-ethz.github.io/p4-utils/usage.html#automated-assignment-strategies).

## Implementing the heavy hitter detector

To solve this exercise we have to program our switch such that is able to forward L3 packets (since h1 and h2 are in different subnets). On
top of that, for every TCP flow we have to count how many times we have seen it, and if its above a threshold block the flow. You will have to
fill the gaps in `heavy_hitter.p4` file, and create two `cli` configuration files, one for `s1` and one for `s2`.

To successfully complete the exercise you have to do the following:

1. Since defining headers is not the objective of this exercise (and it can be a bit cumbersome), you will see that we already provide you the header definitions for `ethernet`, `ipv4` and `tcp`. The header descriptions are at the beginning of `heavy_hitter.p4`

2. Define the parser that is able to parse packets up to `tcp`. Note that for simplicity we do not consider `udp` packets
in this exercise.

3. Define the deparser. Just emit all the headers.

4. Define a IPv4 forwarding table. Implement a match-action table that matches the ip destination address of the packet (use `lpm` match type). In case
of match the table should call `ipv4_forward` action.

5. Define the `ipv4_forward` action. This action takes two parameters as input, destination mac address, and output port. Use the parameters to set the destination mac and
`egress_spec`. Since MAC addresses are not used in a switch to switch communication (as you already have seen last week) set the source mac as the previous destination mac (this is not what a real L3 switch would do,
 we just do it for simplicity. In a more realistic implementation we would create a table
that maps egress_ports to each switch interface mac address, however since this the source mac address is not very important for this exercise just do this swap).
Finally, decrease the packet's TTL by 1.

**Important Note:** since we are in a L3 network, when you send packets from `s1` to `s2` you have to use the dst mac of the switch interface not the mac address of the receiving host, that instead
is done in the very last hop. However, as said above, you can use any MAC address for switch to switch communication.

6. At the beginning of the ingress control, define a register with 4096 fields and set the width of each field to 32. This register will be your counting
bloom filter.

7. Define the action `update_bloom_filter`. In this action you have to implement the bloom filter logic.
For this exercise you have to use two hash functions. Your update bloom filter option should do the following:

    1. Define 4 metadata fields to store the hash output, and values you will read from the register. The size of each variable needs to be 32 bits.
    2. Compute two hash functions using two different algorithms (e.g., crc16 and crc32). Use the `hash` extern function to compute the hash of packets 5-tuple (src ip, dst ip, src port, dst port, protocol). The signature of a hash function is:
   `hash(output_field, (crc16 or crc32), (bit<1>)0, {fields to hash}, (bit<16>)4096)`.
    3. Using the two indexes you got from the hash function, read the register twice and store the values in metadata fields you defined in 1. **Note:** when using constant variables
    in P4 you must cast them otherwise the compiler can not guess the variable type.
    4. Increase the value of both by 1.
    5. Write them back to the register.

8. Implement the main logic (the `apply` block) of your ingress pipeline:

    1. Check if the `ipv4` header is valid.
    2. Check if the `tcp` header is valid.
    3. If both are valid, update the bloom filter.
    4. Check if the two values you read from the register are bigger than a `THRESHOLD` of 1000.
    If so, drop the packet, otherwise `apply` the `ipv4` forwarding table.

9. In this exercise we modify a packet's field for the first time (remember we have to subtract 1 to the ip.ttl field). When doing so, the `ipv4` checksum field needs
to be updated otherwise other network devices (or receiving hosts) might drop the packet. To do that, the [`v1model`](https://github.com/p4lang/p4c/blob/71697086270a7242be6dd90a0bab39b3d1b4395e/p4include/v1model.p4#L514) provides an `extern` function (`update_checksum`) that can be called
inside the `MyComputeChecksum` control to update checksum fields. Update the `hdr.ipv4.hdrChecksum` field hashing all the `ipv4` fields keeping the same order they are declared in the
`ipv4` and excluding the `hdrChecksum` field, since its what we are computing here.

   **Important:** You must set the algorithm to `csum16` so other networking devices or receivers do not drop the packet.

10. Write the `s1-commands.txt` and `s2-commands.txt` file. This file should contain all the `cli` commands needed to fill
the forwarding table you defined in 4. For more information about adding entries to the table check the
[control plane documentation](https://github.com/nsg-ethz/p4-learning/wiki/Control-Plane).

**Important Note**: In order to fill the table you will need two things:

1. Host's MAC addresses: by default hosts get assigned MAC addresses using the following pattern: `00:00:<IP address to hex>`. For example
if `h1` IP's address were `10.0.1.5` the Mac address would be: `00:00:0a:00:01:05`. Alternatively, you can use `iconfig`/`ip` directly in a
host's terminal.

2. Switch port index each host is connected to. There are several ways to figure out the `port_index` to interface mapping. By default
p4-utils add ports in the same order they are found in the `links` list in the `p4app.json` conf file. Thus, with the current configuration
the port assignment would be: `{h1->1, h2->2, h3->3, h4->4}`. However, this basic port assignment might not hold for more complex topologies. Another
way of finding out port mappings is checking the messages printed by when running the `p4run` command:

   ```
   Switch port mapping:
   s1:  1:h1       2:h2    3:h3    4:h4
   ```

   In future exercises we will see an extra way to get topology information.

## Testing your solution

Once you have the `heavy_hitter.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).
   ```bash
   sudo p4run
   ```
   or
   ```bash
   sudo python network.py
   ```

2. Check that you can ping:
   ```
   mininet> pingall
   ```

3. Use the `receive.py` and `send.py` scripts:

   Get a terminal in `h1` and `h2` using the `mx` tool. Run `python receive.py`
   in one of them, in the other run `python send.py <ip_dst>
   <number_of_packets>`. The receiver will start getting packets, you will see
   that it does not receive more than 1000. The `ip` address of `h2` is
   `10.0.2.2`.

4. Check that you can not finish an `iperf`:

   Run `iperf` in the mininet `cli` or getting a terminal. You will see that the first 1000 packets are sent, but then the connection gets blocked.


#### Some notes on debugging and troubleshooting

We have added a [small guideline](https://github.com/nsg-ethz/p4-learning/wiki/Debugging-and-Troubleshooting) in the documentation section. Use it as a reference when things do not work as
expected.