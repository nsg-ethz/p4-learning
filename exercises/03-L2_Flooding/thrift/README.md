# L2 Flooding

## Introduction

In the previous exercise we implemented a very basic l2 forwarding switch that only
knows how to forward packets for which it knows the MAC destination address. In this exercise
we will move one step forward towards our more realistic l2 switch. When a l2 switch does not know to
which port to forward a frame or the MAC destination address is `ff:ff:ff:ff:ff:ff` the switch sends the
packet to all the ports but the one it came from.

In this exercise, first you will have to implement a simplified version in
which packets get forwarded to all ports, once that works, you will have to implement the real l2 flooding, in which packets do not get
sent to the port they came from.

<p align="center">
<img src="images/l2_topology.png" title="L2 Star Topology">
<p/>

## Before Starting

For this exercise the files we provide you are:

- `p4app-all-ports.json` and `p4app-other-ports.json`: *P4-Utils* configuration files for each solution. Both files define the same topology. The only difference between them is the `program` and `cli_input` options.
- `network-all-ports.py` and `network-other-ports.py`: *P4-Utils* topology initilization scripts that can be used instead of the JSON configuration files to run the network.
- `p4src/l2_flooding_all_ports.p4` and `p4src/l2_flooding_other_ports.p4`: p4 program skeletons.
- `send_broadcast.py`: small scapy script to send packets with the l2 broadcast destination address set.

#### Notes about p4app.json

Unlike in previous exercises, for this exercise we do not need the automatic ARP table population at each host.
Actually, during this exercise we want to disable this feature. Once our switches get the feature of broadcasting
packets, ARP requests will be sent everywhere and thus ARP tables will be filled without any problem.

To disable automatic ARP population we added the following line to the `topology` section of the `p4app.json`:
```
"auto_arp_tables": false
```

To disable automatic ARP population we added the following line in the Python scripts:
```bash
net.disableArpTables()
```

**Note:** This option is already disabled in the provided configuration files.

Furthermore, during this exercise you will need to use the `--conf` option when calling `p4run`. By default, if you do not specify anything it tries to find a configuration file named `p4app.json`, which has to be located in the same path. Since in this exercise we provide you with two different configuration files you will have call it as follows:
```bash
sudo p4run --conf <json conf file>
```

On the other hand, if you want to use the Python script to initialize the network, simply run:
```bash
sudo python <script path>
```

You can find all the documentation about `p4app.json` in the *P4-Utils* [documentation](https://nsg-ethz.github.io/p4-utils/usage.html#json).

## Implementing L2 Flooding

We will solve the flooding exercise in two steps. First we will implement the most basic form of flooding packets to all ports.
Then, we will implement a more realistic l2 flooding application that floods packets everywhere, but the
port from where the packet came from. To keep your solutions separated solve each in a different p4 file (skeletons are provided).

### Flooding to all ports

To complete this exercise we will need to define multicast groups, a feature provided
by the `simple_switch` target. Multicast enables us to forward packets to multiple ports. You can find
some documentation on how to set multicast groups in the [simple switch](https://github.com/nsg-ethz/p4-learning/wiki/BMv2-Simple-Switch#creating-multicast-groups) documentation.

Your tasks are:

1. Read the documentation section that talks about multi cast.

2. Define a multicast group with `id=1`.
Create a multicast node that contains all the ports and associate it with the multicast group.

3. Define a `broadcast` action. This action has to set the `standard_metadata.mcast_grp` to the multicast group id
we want to use (in our case 1).

4. Define a match-action table to make switch behave as an l2 packet forwarder. The destination
mac address of each packet should tell the switch witch output port use.

   **Hint**: you can directly copy the table you defined in the previous exercise, and populate it
   with the same mac to port entries.

5. Add the `broadcast` action to the table. This action should be called when there is no hit in the forwarding table
(unknown Mac or `ff:ff:ff:ff:ff:ff`). You can set it as a default action either directly in the table description or
using the `table_set_default` cli command.

6. Apply the table.

### Testing your solution

Once you have the `l2_flooding_all_ports.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).
   ```bash
   sudo p4run --conf p4app-all-ports.json
   ```
   or
   ```bash
   sudo python network-all-ports.py
   ```

2. Sniff interfaces traffic:

    Open 4 terminals and sniff traffic for interfaces `s1-eth1` to `s1-eth4`:

    ```bash
    sudo tcpdump -enn -i <interface_name>
    ```

3. Send a single ping between h1 and h2. Alternatively if you can use the `send_broadcast.py` script to send broadcast
packets from any host, remember to access the namespace before sending packets:

   ```
   mininet> h1 ping h2 -c1

   PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
   64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=6.25 ms

   --- 10.0.0.2 ping statistics ---
   1 packets transmitted, 1 received, 0% packet loss, time 0ms
   rtt min/avg/max/mdev = 6.254/6.254/6.254/0.000 ms
   ```

If you used the ping to test, looking at the `tcpdump` outputs you should see how the ARP request from `h1` got flooded to all ports (even `s1-eth1`).

4. Furthermore you should have full connectivity. Thus, do a ping between all hosts using the cli, and check that you have complete connectivity:

   ```
   mininet> pingall
   *** Ping: testing ping reachability
   h1 -> h2 h3 h4
   h2 -> h1 h3 h4
   h3 -> h1 h2 h4
   h4 -> h1 h2 h3
   *** Results: 0% dropped (12/12 received)
   ```

### Flooding to other ports

Now that we know how to define multicast groups, and we saw that it does work its time to implement a more realistic flooding.
For this exercise the switch will need to take into account the packet's input port and only broadcast to the other ports.

Your tasks are:

1. Define a multicast group per port. For each multicast group associate a node that contains all the ports but one.

2. Define a Mac forwarding table like in the previous exercise (you can mainly copy it). Remember to add the cli commands accordingly. This time
your default action does not need to be `broadcast` it can be an empty action or `NoAction`.

3. Define a new match-action table that matches packet's `ingress_port` and sets the multicast group accordingly. Also define
the action that will be called by the table to set the multicast group.

4. Fill the table entries using the cli file. The entries should match to an ingress port and provide as an action parameter a
multicast group id.

5. Apply the forwarding table, and check if it matched. To do that you can use `table.apply().hit` or `table.apply().action_run` you can
find more information about table hits and misses in the [P4 16 specification](https://p4.org/p4-spec/docs/P4-16-v1.2.4.html#sec-invoke-mau). If there is a
miss (packet needs to be broadcasted) you will have to apply new table defined in `TODO 3` which will set the multicast group.

### Testing your solution

Once you have the `l2_flooding_other_ports.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).
   ```bash
   sudo p4run --conf p4app-other-ports.json
   ```
   or
   ```bash
   sudo python network-other-ports.py
   ```

You can test this exercise by doing the same than in the simple solution. However, this time you should
notice that packets do not get broadcasted to all the ports during the ARP resolution process.

#### Some notes on debugging and troubleshooting

We have added a [small guideline](https://github.com/nsg-ethz/p4-learning/wiki/Debugging-and-Troubleshooting) in the documentation section. Use it as a reference when things do not work as
expected.