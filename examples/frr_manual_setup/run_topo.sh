#!/usr/bin/env bash
# Create namespaces
sudo ip netns add h1
sudo ip netns add h2
sudo ip netns add h3
sudo ip netns add r1
sudo ip netns add r2
sudo ip netns add r3

# Create veth interfaces pairs
sudo ip link add h1-eth0 type veth peer name R1_host
sudo ip link add h2-eth0 type veth peer name R2_host
sudo ip link add h3-eth0 type veth peer name R3_host
sudo ip link add R1_port_R2 type veth peer name R2_port_R1
sudo ip link add R2_port_R3 type veth peer name R3_port_R2

# Enable IPv4 forwarding on routers
sudo ip netns exec r1 sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec r2 sysctl -w net.ipv4.ip_forward=1
sudo ip netns exec r3 sysctl -w net.ipv4.ip_forward=1

# Move the ones that go to hosts
sudo ip link set h1-eth0 netns h1
sudo ip link set h2-eth0 netns h2
sudo ip link set h3-eth0 netns h3
sudo ip link set R1_host netns r1
sudo ip link set R1_port_R2 netns r1
sudo ip link set R2_host netns r2
sudo ip link set R2_port_R1 netns r2
sudo ip link set R2_port_R3 netns r2
sudo ip link set R3_host netns r3
sudo ip link set R3_port_R2 netns r3

# Set ip addres (only hosts) + bring up all interfaces
sudo ip netns exec h1 ifconfig h1-eth0 hw ether 00:00:01:00:01:01 1.0.1.2/24 up
sudo ip netns exec h2 ifconfig h2-eth0 hw ether 00:00:01:00:02:02 1.0.2.2/24 up
sudo ip netns exec h3 ifconfig h3-eth0 hw ether 00:00:01:00:03:03 1.0.3.2/24 up

# Set default gateway
sudo ip netns exec h1 route add default gw 1.0.1.1 dev h1-eth0
sudo ip netns exec h2 route add default gw 1.0.2.1 dev h2-eth0
sudo ip netns exec h3 route add default gw 1.0.3.1 dev h3-eth0

# Set the MTU of these interfaces to be larger than default of
# 1500 bytes, so that P4 behavioral-model testing can be done
# on jumbo frames.
# Disable IPv6 on the interfaces, so that the Linux kernel
# will not automatically send IPv6 MDNS, Router Solicitation,
# and Multicast Listener Report packets on the interface,
# which can make P4 program debugging more confusing.
sudo ip netns exec h1 ip link set h1-eth0 mtu 9500
sudo ip netns exec h1 sysctl net.ipv6.conf.h1-eth0.disable_ipv6=1
sudo ip netns exec h2 ip link set h2-eth0 mtu 9500
sudo ip netns exec h2 sysctl net.ipv6.conf.h2-eth0.disable_ipv6=1
sudo ip netns exec h3 ip link set h3-eth0 mtu 9500
sudo ip netns exec h3 sysctl net.ipv6.conf.h3-eth0.disable_ipv6=1

sudo ip netns exec r1 ip link set R1_host mtu 9500
sudo ip netns exec r1 sysctl net.ipv6.conf.R1_host.disable_ipv6=1
sudo ip netns exec r1 ip link set R1_port_R2 mtu 9500
sudo ip netns exec r1 sysctl net.ipv6.conf.R1_port_R2.disable_ipv6=1

sudo ip netns exec r2 ip link set R2_host mtu 9500
sudo ip netns exec r2 sysctl net.ipv6.conf.R2_host.disable_ipv6=1
sudo ip netns exec r2 ip link set R2_port_R1 mtu 9500
sudo ip netns exec r2 sysctl net.ipv6.conf.R2_port_R1.disable_ipv6=1
sudo ip netns exec r2 ip link set R2_port_R3 mtu 9500
sudo ip netns exec r2 sysctl net.ipv6.conf.R2_port_R3.disable_ipv6=1

sudo ip netns exec r3 ip link set R3_host mtu 9500
sudo ip netns exec r3 sysctl net.ipv6.conf.R3_host.disable_ipv6=1
sudo ip netns exec r3 ip link set R3_port_R2 mtu 9500
sudo ip netns exec r3 sysctl net.ipv6.conf.R3_port_R2.disable_ipv6=1

# Run FRRouters
sudo ip netns exec r1 zebra -d -u root -g root -N r1 -i /tmp/r1-zebra.pid --log file:/tmp/r1-zebra.log --log-level debugging > /tmp/r1-zebra.out 2>&1
sudo ip netns exec r1 ospfd -d -u root -g root -N r1 -i /tmp/r1-ospfd.pid --log file:/tmp/r1-ospfd.log --log-level debugging > /tmp/r1-ospfd.out 2>&1

sudo ip netns exec r2 zebra -d -u root -g root -N r2 -i /tmp/r2-zebra.pid --log file:/tmp/r2-zebra.log --log-level debugging > /tmp/r2-zebra.out 2>&1
sudo ip netns exec r2 ospfd -d -u root -g root -N r2 -i /tmp/r2-ospfd.pid --log file:/tmp/r2-ospfd.log --log-level debugging > /tmp/r2-ospfd.out 2>&1

sudo ip netns exec r3 zebra -d -u root -g root -N r3 -i /tmp/r3-zebra.pid --log file:/tmp/r3-zebra.log --log-level debugging > /tmp/r3-zebra.out 2>&1
sudo ip netns exec r3 ospfd -d -u root -g root -N r3 -i /tmp/r3-ospfd.pid --log file:/tmp/r3-ospfd.log --log-level debugging > /tmp/r3-ospfd.out 2>&1

sudo vtysh -N r1 -f r1.conf
sudo vtysh -N r2 -f r2.conf
sudo vtysh -N r3 -f r3.conf

# Enable tcpdump on all interfaces
if [ ! -d "pcap" ]; then
  mkdir pcap
fi

sudo ip netns exec h1 tcpdump -i h1-eth0 -Q in --packet-buffered -w ./pcap/h1-eth0_in.pcap &
sudo ip netns exec h1 tcpdump -i h1-eth0 -Q out --packet-buffered -w ./pcap/h1-eth0_out.pcap &
sudo ip netns exec h2 tcpdump -i h2-eth0 -Q in --packet-buffered -w ./pcap/h2-eth0_in.pcap &
sudo ip netns exec h2 tcpdump -i h2-eth0 -Q out --packet-buffered -w ./pcap/h2-eth0_out.pcap &
sudo ip netns exec h3 tcpdump -i h3-eth0 -Q in --packet-buffered -w ./pcap/h3-eth0_in.pcap &
sudo ip netns exec h3 tcpdump -i h3-eth0 -Q out --packet-buffered -w ./pcap/h3-eth0_out.pcap &

sudo ip netns exec r1 tcpdump -i R1_host -Q in --packet-buffered -w ./pcap/R1_host_in.pcap &
sudo ip netns exec r1 tcpdump -i R1_host -Q out --packet-buffered -w ./pcap/R1_host_out.pcap &
sudo ip netns exec r2 tcpdump -i R2_host -Q in --packet-buffered -w ./pcap/R2_host_in.pcap &
sudo ip netns exec r2 tcpdump -i R2_host -Q out --packet-buffered -w ./pcap/R2_host_out.pcap &
sudo ip netns exec r3 tcpdump -i R3_host -Q in --packet-buffered -w ./pcap/R3_host_in.pcap &
sudo ip netns exec r3 tcpdump -i R3_host -Q out --packet-buffered -w ./pcap/R3_host_out.pcap &

sudo ip netns exec r1 tcpdump -i R1_port_R2 -Q in --packet-buffered -w ./pcap/R1_port_R2_in.pcap &
sudo ip netns exec r1 tcpdump -i R1_port_R2 -Q out --packet-buffered -w ./pcap/R1_port_R2_out.pcap &

sudo ip netns exec r2 tcpdump -i R2_port_R1 -Q in --packet-buffered -w ./pcap/R2_port_R1_in.pcap &
sudo ip netns exec r2 tcpdump -i R2_port_R1 -Q out --packet-buffered -w ./pcap/R2_port_R1_out.pcap &
sudo ip netns exec r2 tcpdump -i R2_port_R3 -Q in --packet-buffered -w ./pcap/R2_port_R3_in.pcap &
sudo ip netns exec r2 tcpdump -i R2_port_R3 -Q out --packet-buffered -w ./pcap/R2_port_R3_out.pcap &

sudo ip netns exec r3 tcpdump -i R3_port_R2 -Q in --packet-buffered -w ./pcap/R3_port_R2_in.pcap &
sudo ip netns exec r3 tcpdump -i R3_port_R2 -Q out --packet-buffered -w ./pcap/R3_port_R2_out.pcap &

# Check OSPF convergence time using ping
sudo ip netns exec h1 ping 1.0.3.2