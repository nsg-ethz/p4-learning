# Simple Routing

## Introduction

The goal of this exercise is to implement and provide a control plane to the ECMP routing exercise from 2 weeks ago.
Unlike in the previous exercises where you specified the entries for the forwarding tables manually,
we will now implement a controller that generates and installs forwarding rules automatically, based on the network topology.

In traditional networks the control plane is the brain of any networking device. The control plane is in charge of deciding
where packets have to be sent. Distributed control planes exchange topology information with other devices and compute which is
the best way of sending traffic based on some routing protocol (RIP, OSPF, BGP).

To simplify things a lot in this exercise we will not implement a distributed and dynamic control plane like the ones mentioned above, but something simple,
centralized and static. However, your controller should be able to automatically populate the ECMP exercise tables for any topology.

### What is already provided

For this exercise we provide you with the following files:

- `p4app.json`: describes the topology we want to create with the help of mininet and p4-utils package. It is the same topology we used for the ECMP exercise.
- `network.py`: a Python scripts that initializes the topology using *Mininet* and *P4-Utils*. One can use indifferently `network.py` or `p4app.json` to start the network.
- `p4src/ecmp.p4`: we will use the solution of the [03-ECMP](../../03-ECMP/p4runtime) exercise as starting point.
- `send.py`: a small python script to generate multiple packets with different tcp port.
- `routing-controller.py`: routing controller skeleton. The controller uses global topology information and the simple switch `thrift_API` to populate the routing tables.
- `topology_generator.py`: Python script that automatically generates `p4app` configuration files. It allows you to generate 3 types of topologies: linear, circular, and random (with a node number and degree). Run it with `-h` option to see the command line parameters.
- `network_generator.py`: Python script that automatically generates `network.py` scripts. It allows you to generate 3 types of topologies: linear, circular, and random (with a node number and degree). Run it with `-h` option to see the command line parameters.

#### Notes about p4app.json

For this exercise we will use the `l3` assignment strategy. Unlike the `mixed` strategy where hosts connected to the same
switch formed a subnetwork and each switch formed a different domain. In the `l3` assignment, we consider switches to only work
at the layer 3, meaning that each interface must belong to a different subnetwork. If you use the namings `hY` and `sX` (e.g h1, h2, s1, s2...),
the IP assignment will go as follows:

   1. Host IPs: `10.x.y.2`, where `x` is the id of the gateway switch, and `y` is the host id.
   2. Switch ports directly connected to a host: `10.x.y.1`, where `x` is the id of the gateway switch, and `y` is the host id.
   3. Switch to Switch interfaces: `20.sw1.sw2.<1,2>`. Where `sw1` is the id of the first switch (following the order in the `p4app` link definition), `sw2` is the
   id of the second switch. The last byte is 1 for sw1's interface and 2 for sw2's interface.

Note that it is the first time we assign IP addresses to a switch. However, it is very important to note that actually `p4-utils` will not assign those IPs
to the switches, but it will save them so they can be `virtually` used for some switch functionality (we will see what this means later).

You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://nsg-ethz.github.io/p4-utils/usage.html#json). Also, you can find information about assignment strategies [here](https://nsg-ethz.github.io/p4-utils/usage.html#automated-assignment-strategies).

## Understanding the router's P4 program

The data plane program of this exercise is identical to the solution of last week's ECMP exercise (you are free to use your own solution instead of the one we provide you if you prefer, however
the following description will be based on the ECMP solution we provide).

Take a moment to go through the P4 code again to remind yourself how the program works before starting to implement the controller.

## Implementing the router's control plane program

The main task of the controller (we provide a skeleton in `routing-controller.py`) is to translate the network topology
(stored in `topology.json`) to match-action table entries. For example for the topology that we used in last week's ECMP exercise,
 it should run the following commands to fill the `ipv4_lpm` and `ecmp_group_to_nhop` tables in switch `s1` (note that the IPs used below follow the
 `l3` assignment strategy and not the `mixed` one so IPs will not match to the ones used in the previous exercise):


```
table_set_default ipv4_lpm drop
table_set_default ecmp_group_to_nhop drop

table_add ipv4_lpm set_nhop 10.1.1.2/32 =>  00:00:0a:01:01:02 1
table_add ipv4_lpm ecmp_group 10.6.2.2/32 => 1 4

table_add ecmp_group_to_nhop set_nhop 1 0 =>  00:00:00:02:01:00 2
table_add ecmp_group_to_nhop set_nhop 1 1 =>  00:00:00:03:01:00 3
table_add ecmp_group_to_nhop set_nhop 1 2 =>  00:00:00:04:01:00 4
table_add ecmp_group_to_nhop set_nhop 1 3 =>  00:00:00:05:01:00 5
```

You have to write your controller application in the  `routing-controller.py` file that we already provided you. You will see that we already implemented some
small functions that use the `Topology` and `SimpleSwitchThriftAPI` objects from p4utils. Among others, the provided functions do:

   1. `connect_to_switches()`: function that establishes a connection with the simple switch `thrift` server using the `SimpleSwitchThriftAPI` object and saves those
   objects in the `self.controllers` dictionary. This dictionary has the form of: `{'sw_name' : SimpleSwitchThriftAPI()}`.
   2. `reset_states()`: iterates over the `self.controllers` object and runs the `reset_state` function which will empty the state (registers, tables, etc) for every switch.
   3. `set_table_defaults()`: for each p4 switch it sets the default action for `ipv4_lpm` and `ecmp_group_to_nhop` tables.

In this exercise your task is to implement the `route` function which is in charge of populating the table entries such that you can route traffic using the shortest path in the network. Furthermore, if multiple equal cost paths are found you have to assign them to an ECMP group.

At a high level, the `route` function should do the following:

1. Iterate over all pairs of switches in the topology
2. Compute all the shortest paths between each of these pairs of switches
3. Install the table entries needed depending on the following 3 scenarios:
   1. If source switch and destination switch are the same. Install an entry for each directly connected host: You need host ip (use `/32`), mac address, and in which port index it is connected to the switch.
   2. If there is a single path between src switch and destination switch and the destination switch has direct hosts connected: this time use the next hop to get the output port and the destination mac address.
   3. If there are multiple paths between src switch and destination switch and the destination switch has direct hosts connected: create a ecmp group (as in the example above) for all multiple next hops needed to reach
   the destination switch. If for the same source switch the same multiple hops have to be used for another destination use the already defined ecmp group.

To get information about the shortest paths, ip addresses, mac addresses, port indexes and how nodes are connected between each other you will have to strongly utilize the topology object from `p4-utils`. To implement the routing function you will have to strongly utilize the topology object from `p4-utils`.

You can find documentation about all the functions you have to use to solve this
exercise in the P4-Utils
[documentation](https://nsg-ethz.github.io/p4-utils/p4utils.utils.topology.html#p4utils.utils.topology.NetworkGraph)
page (all the functions documented should be enough to solve the exercise).
However, if you want to, you can also find the topology object source code
[here](https://github.com/nsg-ethz/p4-utils/blob/master/p4utils/utils/topology.py)
and use other functions.

## Testing your solution

Once you completed your implementation of the `route` function of the controller, you can test the program the same way as the ECMP exercise last week:

1. Start the topology (this will also compile and load the program).
   ```bash
   sudo p4run
   ```

   or
   ```bash
   sudo python network.py
   ```

2. Run the controller.
   ```bash
   python routing-controller.py
   ```

3. Check that you can ping:
   ```
   mininet> pingall
   ```

4. check that ECMP works: monitor the 4 links from `s1` that will be used during `ecmp` (from `s1-eth2` to `s1-eth5`). Doing this you will be able to check which path is each flow
taking.
   ```bash
   sudo tcpdump -enn -i s1-ethX
   ```

4. Ping between two hosts:

   You should see traffic in only 1 or 2 interfaces (due to the return path).
   Since all the ping packets have the same 5-tuple.

5. Do iperf between two hosts:

   You should also see traffic in 1 or 2 interfaces (due to the return path).
   Since all the packets belonging to the same flow have the same 5-tuple, and thus the hash always returns the same index.

6. Get a terminal in `h1`. Use the `send.py`.
   ```bash
   python send.py 10.6.2.2 1000
   ```

   This will send `tcp syn` packets with random ports. Now you should see packets going to all the interfaces, since each packet will have a different hash.


### Testing with another topology

Now you have a controller that should be able to populate automatically the routing tables of any topology. To test that your solution does work with other topologies you can use the
`topology_generator.py` script we provided you and generate random topologies:

```bash
python topology_generator.py --output_name <name.json> --topo random -n <number of switches to use> -d <average switch degree>
```

This will create a random topology with `n` switches that have on average `d` interfaces (depending on `n`, `d` might not be possible). Also each switch will have one host directly connected to it (so `n` hosts).

For example you can create a random topology with 40 switches and an average degree of 4:

```bash
python topology_generator.py --output_name 40-switches.json --topo random -n 40 -d 4
```

Run the random topology:

```bash
sudo p4run --config 40-switches.json
```

If you want to use Python scripts instead of JSON files, you may want to run:

```bash
python network_generator.py --output_name 40-switches.json --topo random -n 40 -d 4
```

and
```bash
sudo python 40-switches.py
```

Now run the controller, and check that your can send traffic to all the nodes. Furthermore, check that ECMP works.

#### Some notes on debugging and troubleshooting

We have added a [small guideline](https://github.com/nsg-ethz/p4-learning/wiki/Debugging-and-Troubleshooting) in the documentation section. Use it as a reference when things do not work as expected.
