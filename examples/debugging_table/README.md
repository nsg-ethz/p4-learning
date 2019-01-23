# Debugging table

```
+--+      +--+     ++-+
|h1+------+s1+-----+h2+
+--+      +-++     +--+

```

## Introduction

This is a very basic example in which we show how tables can be used to
inspect the value of headers/metadata fields when the packet is crossing
the switch.

When there is a match in a table the debugging engine will write the
value of the matched field in the log file and thus it will allow us to
better debug our programs

This program just forwards IPv4 packets using a longest prefix match table,
however it also crosses a table that matches to all the standard_metadata fields,
allowing us to see whats their value for each packet.

### How to run

Start the topology:

```
sudo p4run
```

Any packet will trigger the use of the debugging table, and thus
just right after starting the topology we can already check the log file
which is located at `./log/s1.log`:

```
[20:16:38.545] [bmv2] [T] [thread 21879] [0.0] [cxt 0] Applying table 'MyIngress.debug.dbg_table'
[20:16:38.545] [bmv2] [D] [thread 21879] [0.0] [cxt 0] Looking up key:
* standard_metadata.ingress_port            : 0002
* standard_metadata.egress_spec             : 0000
* standard_metadata.egress_port             : 0000
* standard_metadata.clone_spec              : 00000000
* standard_metadata.instance_type           : 00000000
* standard_metadata.packet_length           : 0000004e
* standard_metadata.enq_timestamp           : 00000000
* standard_metadata.enq_qdepth              : 000000
* standard_metadata.deq_timedelta           : 00000000
* standard_metadata.deq_qdepth              : 000000
* standard_metadata.ingress_global_timestamp: 000000039a24
* standard_metadata.egress_global_timestamp : 000000000000
* standard_metadata.lf_field_list           : 00000000
* standard_metadata.mcast_grp               : 0000
* standard_metadata.resubmit_flag           : 00000000
* standard_metadata.egress_rid              : 0000
* standard_metadata.checksum_error          : 00
* standard_metadata.recirculate_flag        : 00000000
* parser_error_as_int                       : 00
```





