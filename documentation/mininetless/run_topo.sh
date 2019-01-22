#!/usr/bin/env bash
# Create namespaces
sudo ip netns add h1
sudo ip netns add h2

# Bring the loopback interfaces up
sudo ip netns exec h1 ifconfig lo up
sudo ip netns exec h2 ifconfig lo up

# Create veth interfaces pairs
sudo ip link add h1-eth0 type veth peer name s1-eth0
sudo ip link add h2-eth0 type veth peer name s2-eth0
sudo ip link add s1-eth1 type veth peer name s2-eth1

#declare array of interfaces names
declare -a arr=("h1-eth0" "h2-eth0" "s1-eth0" "s1-eth1" "s2-eth0" "s2-eth1")

# Set the MTU of these interfaces to be larger than default of
# 1500 bytes, so that P4 behavioral-model testing can be done
# on jumbo frames.
# Disable IPv6 on the interfaces, so that the Linux kernel
# will not automatically send IPv6 MDNS, Router Solicitation,
# and Multicast Listener Report packets on the interface,
# which can make P4 program debugging more confusing.
for intf in "${arr[@]}"
do
    ip link set "$intf" mtu 9500
    sysctl net.ipv6.conf.${intf}.disable_ipv6=1
done

# Move the ones that go to hosts
sudo ip link set h1-eth0 netns h1
sudo ip link set h2-eth0 netns h2

# Set ip addres (only hosts) + bring up all interfaces
sudo ip netns exec h1 ifconfig h1-eth0 hw ether 00:00:00:00:01:01 10.0.1.1/24 up
sudo ip netns exec h2 ifconfig h2-eth0 hw ether 00:00:00:00:02:02 10.0.2.2/24 up
sudo ip link set dev s1-eth0 up
sudo ip link set dev s1-eth1 up
sudo ip link set dev s2-eth0 up
sudo ip link set dev s2-eth1 up

# Set default gateway
sudo ip netns exec h1 route add 10.0.1.254 dev h1-eth0
sudo ip netns exec h2 route add 10.0.2.254 dev h2-eth0

sudo ip netns exec h1 route add default gw 10.0.1.254 h1-eth0
sudo ip netns exec h2 route add default gw 10.0.2.254 h2-eth0

# Set ARP tables
sudo ip netns exec h1 arp -i h1-eth0 -s 10.0.1.254 00:00:00:01:01:00
sudo ip netns exec h2 arp -i h2-eth0 -s 10.0.2.254 00:00:00:02:02:00

CURRENT_PATH=pwd

# Compile p4 program
p4c --target bmv2 --arch v1model --std p4-16 forwarding.p4 -o .

# Run Switches
sudo simple_switch -i 1@s1-eth0 -i 2@s1-eth1  --thrift-port 9090 --nanolog ipc:///tmp/bm-0-log.ipc --device-id 0 forwarding.json &
sudo simple_switch -i 1@s2-eth0 -i 2@s2-eth1  --thrift-port 9091 --nanolog ipc:///tmp/bm-1-log.ipc --device-id 1 forwarding.json &

sleep 0.5
echo -ne 'Waiting for switches to boot.'
for i in $(seq 1 10); do
  sleep 0.2
  echo -ne '.'
done
echo '.'

# Populate switches with CLI
simple_switch_CLI --thrift-port 9090 < s1-commands.txt
simple_switch_CLI --thrift-port 9091 < s2-commands.txt


