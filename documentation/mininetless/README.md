# Manual Topology Setup

In this example we show how to create a virtual topology without using any helper ([mininet](), [p4utils](), ...). For 
that we will manually create hosts using unix namespaces and interconnect them using virtual interfaces and bmv2
switches.

The goal of this example is to show what does mininet do when you define a topology. Note that mininet provides you with
much richer set of options and does many more things. Here, we just show the minimum needed to try a very basic p4 example.


**Topology:**

```
+--+     +--+     ++-+     +--+
|h1+-----+s1+-----+s2+-----+h2|
+--+     +-++     +--+     +--+  
```

### Create Linux Network Namespaces

We first create a pair of linux network namespaces
 (see more: [article](https://blogs.igalia.com/dpino/2016/04/10/network-namespaces/), 
 [man page](https://www.systutorials.com/docs/linux/man/8-ip-netns/)).
  
 Linux namespaces provide a network stack for all the processes running within the namespace. Including network
 interfaces, routing tables, iptables rules, etc. Thus, network virtualization tools (like mininet) use linux network namespaces to
 instanciate isolated nodes in a topology (hosts, switches, routers, etc)
 
 To create network namespaces we can use the `ip` tool, specifically `ip-netns` command.
 
```bash
$ sudo ip netns add h1
$ sudo ip netns add h2
```

Once we have the namespaces we can run shell commands using:

```bash
$ sudo ip netns exec <namespace-name> <cmd>
```

Alternatively we can get a shell:
 
 ```bash
 $ sudo ip netns exec <namespace-name> bash
 ```

### Adding Virtual Interfaces

To interconnect namespaces between them we need to create virtual ethernet interfaces and assign them. Virtual interfaces
come in connected pairs, thus if you send a packet to one side of the pair you get the packet in the other side. 

AS before, we use `ip` to create three `veth` pairs:

```bash
$ sudo ip link add h1-eth0 type veth peer name s1-eth0
$ sudo ip link add h2-eth0 type veth peer name s2-eth0
$ sudo ip link add s1-eth1 type veth peer name s2-eth1
```

If you list the number of interfaces, you will see that six new interfaces have been added to the `default/global` namespace. Next
we will move two of those interfaces to `h1` and `h2` network namespaces:
 
```bash
sudo ip link set h1-eth0 netns h1
sudo ip link set h2-eth0 netns h2
```

We leave the rest of interfaces (the ones we will connect to the switches) in the `global` namespace due to the fact that
`bmv2` switches can not be run inside network namespaces (or at least they do not seem to work). However, that is fine since 
the switches do not need to run the `TCP/IP` stack they just need to receive packets from one interface, process them, and send 
them to another interface.

**Optional**:

Optionally we can change the interfaces MTU to `9500` so we can play with bigger packets. Furthermore, we can disable `ipv6`, to avoid
seeing some automatically generated packets by the `ipv6` stack.

```bash
declare -a arr=("h1-eth0" "h2-eth0" "s1-eth0" "s1-eth1" "s2-eth0" "s2-eth1")
for intf in "${arr[@]}"
do
    ip link set "$intf" mtu 9500
    sysctl net.ipv6.conf.${intf}.disable_ipv6=1
done
```

In the next steps we need to bring the interfaces up, assign IP, configure gateways and fill arp tables.

#### Setup Interfaces

First we bring the loopback interfaces at the namespaces:

```bash
sudo ip netns exec h1 ifconfig lo up
sudo ip netns exec h2 ifconfig lo up
```

Then we bring the virtual interfaces up, and configure the MAC and IP addresses at the hosts.

```bash
sudo ip netns exec h1 ifconfig h1-eth0 hw ether 00:00:00:00:01:01 10.0.1.1/24 up
sudo ip netns exec h2 ifconfig h2-eth0 hw ether 00:00:00:00:02:02 10.0.2.2/24 up
sudo ip link set dev s1-eth0 up
sudo ip link set dev s1-eth1 up
sudo ip link set dev s2-eth0 up
sudo ip link set dev s2-eth1 up
```

Since hosts belong to different subnetworks we need to configure a gateway that will be used for packets going to
`0.0.0.0`. For that we assign as a gateway a `fake IP` and which interface has to be used as a gateway.

```bash
sudo ip netns exec h1 route add default gw 10.0.1.254 h1-eth0
sudo ip netns exec h2 route add default gw 10.0.2.254 h2-eth0
```

Setting the gateway address and interface is not enough, when the host tries to communicate with the gateway it will use 
the link layer (L2), for that to happen the `ARP` (address resolution protocol) will be used in order to discover the MAC address
 of `10.0.X.254`, however the switches in this example are not programmed to respond to `ARP`. To bypass that, we just populate
 the `ARP` tables at each host with `fake MAC` addresses:
 
```bash
sudo ip netns exec h1 arp -i h1-eth0 -s 10.0.1.254 00:00:00:01:01:00
sudo ip netns exec h2 arp -i h2-eth0 -s 10.0.2.254 00:00:00:02:02:00
```

### Compile P4 Program

To run the p4 program in the bmv2 switch we first have to compile it using the `p4c` compiler:

```bash
p4c --target bmv2 --arch v1model --std p4-16 forwarding.p4 -o .
```

### Run Bmv2 Switches

Next we run two `simple_switches` instances, attach the interfaces we want to have, and provide the compile p4 program.

```bash
sudo simple_switch -i 1@s1-eth0 -i 2@s1-eth1  --thrift-port 9090 --nanolog ipc:///tmp/bm-0-log.ipc --device-id 0 forwarding.json &
sudo simple_switch -i 1@s2-eth0 -i 2@s2-eth1  --thrift-port 9091 --nanolog ipc:///tmp/bm-1-log.ipc --device-id 1 forwarding.json &
```

### Populate Tables with Simple Switch CLI

As a last step we populate the `ipv4_lpm` table using the `simple_switch_CLI` and a file with the commands we want to type in. 

```bash
simple_switch_CLI --thrift-port 9090 < s1-commands.txt
simple_switch_CLI --thrift-port 9091 < s2-commands.txt
```

### Ping Test

To test our virtual network, we access `h1`, spawn a shell, and ping `h2`:

```bash
ip netns exec h1 bash

$ ping 10.0.2.2
PING 10.0.2.2 (10.0.2.2) 56(84) bytes of data.
64 bytes from 10.0.2.2: icmp_seq=1 ttl=62 time=4.89 ms
64 bytes from 10.0.2.2: icmp_seq=2 ttl=62 time=4.19 ms
```