# P4 Examples

Compilation of different P4 examples. In overall, these examples cover
almost all the `simple switch` features (with some exceptions). Thus, they
can perfectly be used as a guide or cheat sheet.

To run the examples without any modification you have to first install [p4-utils](https://github.com/nsg-ethz/p4-utils).
P4-utils its a set of tools built on top of mininet that help with the developement and testing of p4 networks.

## Examples

Examples are classified in different categories depending on which is the
feature they `exhibit` the most.

### Basic Examples

* [Packet reflector](./reflector)
* [Packet Repeater](./repeater)
* [Source Routing](./source_routing)
* [Dropping packets with wrong checksum](./verify_checksum)
* [Equal-Cost Multipath](./ecmp)
* [Flowlet Switching](./flowlet_switching)
* [Simple L3 Forwarding 1](./ip_forwarding)
* [Simple L3 Forwarding 2](./ip_forwarding_two_tables)


### Registers, Counters, Meters
* [Counters](./counter)
* [Heavy Hitter Detection](./heavy_hitter)
* [Read/Write the content of registers through the CLI](./read_write_registers_cli)
* [Simple stateful firewall](./stateful_firewall)
* [Meters](./meter)

### Clone, Recirculate, Resubmit
* [Simple Recirculation](./recirculate)
* [Recirculate and add headers to the packet](./recirculate_and_add_header)
* [Comparing resubmit with recirculate](./resubmit_recirculate)

### Monitoring Switch State
* [Explicit Congestion Notification (ECN)](./ecn)
* [Simple In-Band Network Telemtry](./simple_int)

### Communicating with the Control Plane
* [Cloning packets to a controller](./copy_to_cpu)
* [Digesting packets to a controller](./digest_messages)
* [Learning Switch](./l2_learning)

### Misc
* [Using tables for debugging](./debugging_table)
* [How to run P4 code with just command lines?](./manual_setup)
* [Multicasting/Broadcasting Packets](./multicast)