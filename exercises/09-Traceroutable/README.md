# Traceroutable Network

## Introduction

In this exercise, we will extend our P4 router with an additional feature: responding to `traceroute` packets, i.e. packets where the IPv4 TTL (time to live)
value is equal to 1. If a router receives such a packet, it generates an ICMP `Time Exceeded` message and sends it back to the original sender of the expired packet.
Thus, our objective is to make the `traceroute` or similar tools work within our network.

In brief, traceroute works as follows: it sends several packets starting with `TTL=1` and it increases the TTL by 1 for each consequent packet. As you already know, each internet router
decreases the IP TTL by 1 and sends back ICMP messages when it reaches 0. By sending packets with an increasing TTL, traceroute is able to `trace` the path packets take from the source
to a given destination.

For a detailed description of how traceroute works, have a look at the [Wikipedia article](https://en.wikipedia.org/wiki/Traceroute).
For more information about ICMP (i.e. the protocol that is used for the replies to expired traceroute packets), look at this
[Wikipedia article](https://en.wikipedia.org/wiki/Internet_Control_Message_Protocol#Time_exceeded) or its [RFC](https://tools.ietf.org/html/rfc792).

## Before starting

Before you start this exercise, update `p4-utils`, some new features and bugs were fixed during the last week:

```bash
cd ~/p4-tools/p4-utils
git pull
```

Further, you need the `traceroute` tool for this exercise (it might be installed already). Install it by running this command in a terminal:

```bash
sudo apt-get install traceroute
```

### What is already provided

For this exercise we provide you with the following files:

  *  `p4app.json`: describes the topology we want to create with the help
     of mininet and p4-utils package.
  *  `p4src/ecmp.p4`: we will use the solution of the [03-ECMP](../03-ECMP) exercise as starting point.
  *  `send.py`: a small python script to generate multiple packets with different tcp port.
  *  `routing-controller.py`: routing controller skeleton. The controller uses global topology
  information and the simple switch `runtime_API` to populate the routing tables.
  * `topology_generator.py`: python script that automatically generates `p4app` configuration files.
   It allows you to generate 3 types of topologies: linear, circular, and random (with a node number and degree). Run it with `-h` option to see the
   command line parameters.
  * `traceroute.py`: python script that implements a simple version of traceroute using `tcp` probes. It can be used to script traceroute tests.

#### Notes about p4app.json

For this exercise we will use the `l3` assignment strategy. Unlike the `mixed` strategy where hosts connected to the same
switch formed a subnetwork and each switch formed a different domain. In the `l3` assignment, we consider switches to only work
at the layer 3, meaning that each interface must belong to a different subnetwork. If you use the namings `hY` and `sX` (e.g h1, h2, s1, s2...),
the IP assignment will go as follows:

   1. Host IPs: `10.x.y.2`, where `x` is the id of the gateway switch, and `y` is the host id.
   2. Switch ports directly connected to a host: `10.x.y.1`, where `x` is the id of the gateway switch, and `y` is the host id.
   3. Switch to Switch interfaces: `20.sw1.sw2.<1,2>`. Where `sw1` is the id of the first switch (following the order in the `p4app` link definition), `sw2` is the
   id of the second switch. The last byte is 1 for sw1's interface and 2 for sw2's interface.

Note that it is the second time we assign IP addresses to a switch. However, it is very important to note that actually `p4-utils` will not assign those IPs
to the switches, but it will save them so they can be `virtually` used for some switch functionality (we will see what this means later).

You can find all the documentation about `p4app.json` in the `p4-utils` [documentation](https://github.com/nsg-ethz/p4-utils#topology-description).

## Understanding traceroute

Before starting with the implementation, we will have a look at the packets that `traceroute` sends and receives.
To do this, open a terminal and type `sudo wireshark &` to open Wireshark. Then, select the interface `eth0` and start capturing traffic. You will see
a lot of packets being sent and received, to remove them you can apply the following filter at the filter bar: `ip.ttl < 10 || icmp`.
Now run the following command in the terminal:

```bash
sudo traceroute -n -q 1 -f 1 -m 1 -T ethz.ch
```

This will send a single traceroute (`TCP`) packet with `TTL=1` towards `ethz.ch`. In Wireshark, you should see a `TCP` packet as
well as the corresponding `ICMP` reply. Take a close look at these to packets to understand how a router builds these `ICMP` replies. You can use the
`ICMP` replied by `ethz.ch` as a reference. For example, you can see how the `IP` header changes, what the `ICMP` header and body contain, etc.


## Implementing the traceroutable switch

Take the solution from the previous exercise (both p4 code and `routing-controller.py`). To implement our traceroutable switch we will have to make two additions: first
we will have to add a new table to the p4 program that maps egress_ports to the `IP` address of the switch for that port.  You will also have to extend the controller with
a small function that populates this table for each switch. Second we will have to extend the p4 program so the switch replies to packets with `TTL=1` with ICMP packets to the original
sender.

#### Adding the output port to IP table

Before we implement the generation of ICMP replies to expired packets in P4, we will have to add a new table to the code we already have from the previous exercise. This table will
be used during the ICMP reply process to set the `ipv4` source address for the packets that the switch generates. This IP address will then be used by the traceroute tool
to identify which router (and interface) is the packet coming from.

You have to do tho things:

1. Define a table called `icmp_ingress_port` that matches to the packet's `ingress_port` (the ingress port will be used as egress port for the ICMP replies). This
table should call an action (`set_src_icmp_ip`) that takes an IP address as a parameter and sets it to the `hdr.ipv4_icmp` source IP address. You will in the next section what this `ipv4_icmp`
header is.

2. Implement the `set_icmp_ingress_port_table` function in the `routing-controller.py`.  In particular, we want to assign each
interface of the switch a separate IP address. For this you will have to fill the `icmp_ingress_port` table with the mapping from
ingress port to the IP address associated to that respective port. To get information about the port to IP you will have to use the `self.topo` object. For more
information see the [documentation](https://github.com/nsg-ethz/p4-utils#topology-object). Hint: there is a function to get all the interfaces a node has, with that you
should be able to get their IPs and port number.

#### Replying with ICMP packets

To implement the ICMP packet replying system, you should:

1. Add the ICMP header to your `headers.p4` file.

2. Extend the `headers` struct with the `icmp` header and a second `ipv4` header (you can call it `ipv4_icmp`). As you should have seen during your traceroute tests,
the ICMP packet should contain its own `ipv4` header and the `ipv4` header of the expired packet. As you see from the headers and the parser (from the ECMP solution),
we only consider TCP as the transport layer protocol (not UDP). Therefore, you can focus on TCP (and IP) packets in your implementation.

3. Extend the deparser control block with the two new headers. Make sure you emit the things in the right order. For that check again how the ICMP packet looks like.

4. We now start extending the implementation of the ingress pipeline. Here, you can first check whether the received
packet's TTL value is `>1`. If so, you forward the packet as usual (using ECMP).

5. If the TTL is equal to `1` (and the packet is `ipv4` and `tcp` valid), the packet expires at this router and you need to send an answer back to the sender. (make sure the packet does not go through the normal forwarding tables).
To transform the received TCP packet into an ICMP reply, you need to do the following:
    - set the additional headers (`ipv4_icmp`, `icmp`) to valid (by calling `hdr.X.setValid()`)
    - set the egress port such that the packet is sent through the port where it arrived
    - swap the source and destination MAC addresses
    - set the source IP address to the address that belongs to the interface where the packet arrived (using the table `icmp_ingress_port` from above)
    - set the correct values for the `ipv4_icmp` and the `icmp` header (you may use the packets that you captured in Wireshark before as a template)
    - make sure you set the `ipv4_icmp.totalLen` to the right value otherwise wireshark (or other tools) will not be able to compute the checksum properly.
    - truncate the packet to 70 bytes (using `truncate((bit<32>)70);`) to remove remaining parts from the original packets.

6. Since both the IP headers and the ICMP header contain checksums, you need to compute them in the `MyComputeChecksum` control.
You can use the IP checksum from previous exercises as a template for the `ipv4_icmp` checksum. To compute the checksum of the `icmp` header you have to hash all the fields
from the ICMP header together with the payload (original IP header + the first 8 bytes from the tcp header). For this checksum use the same algorithm you used before (`HashAlgorithm.csum16`).

## Testing your solution

Once you completed your implementation, you can test the program using the `traceroute.py` script or the real `traceroute` tool. If you use the `traceroute` tool, bear in mind that we only implemented replies to TCP packets while the tool sends UDP packets by default. Add the `-T` parameter to use TCP packets.

1. Start the topology (this will also compile and load the program).

   ```bash
   sudo p4run
   ```

2. Run the controller.

   ```bash
   python routing-controller.py
   ```

3. Check that you can ping:

   ```bash
   mininet> pingall
   ```

4. Traceroute between two hosts:

   You can either use our own implementation (`traceroute.py`) or the default `traceroute` tool:

   ```python -i traceroute.py
   for sport in range(6000,6020):
       print traceroute(dst="10.6.2.2",sport=sport, dport=80)
   ```

   ```bash
   mininet> h1 traceroute -n -w 0.5 -q 1 -T --sport=<src_port> --port=<dst_port> 10.6.2.2
   ```
   (to make it faster, we disable DNS lookups (`-n`), decrease the waiting time `-w`, send only one packet per TTL (`-q`) and a fixed source and destination port (`--sport`,`--dport`) to get the actual path of a flow despite ECMP)


  Note that the second router (s2, s3, s4 or s5) will always indicate which path the flow with a given 5-tuple would take in our simple topology.

### Testing with another topology

As in the previous exercise, you can test that your solution does work with other topologies with the
`topology_generator.py` script we provided you and which generates random topologies:

```bash
python topology_generator --output_name <name.json> --topo random --n <number of switches to use> -d <average switch diamiter>
```

This will create a random topology with `n` switches that have on average `d` interfaces (depending on `n`, `d` might not be possible). Also each switch will have one host directly connected to it (so `n` hosts).

Run the random topology:

```bash
sudo p4run --config <name.json>
```

Do the rest of the steps we did in the previous section. By running multiple traceroutes between two hosts you will be able to discover which path (or paths) are being used !

#### Some notes on debugging and troubleshooting

If you don't receive replies to your traceroute queries, you can use Wireshark to look at the packets (i.e. capture the host's interface). Wireshark will tell you if the packet cannot be parsed (e.g. because the structure is not correct) or if the checksums are incorrect.

We have added a [small guideline](../../documentation/debugging-and-troubleshooting.md) in the documentation section. Use it as a reference when things do not work as
expected.

