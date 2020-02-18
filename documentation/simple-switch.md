# Simple Switch

> This documentation is strongly inspired by [simple switch documentation](https://github.com/p4lang/behavioral-model/blob/master/docs/simple_switch.md)

## Introduction

The simple switch target is the de-facto architecture used in P4 development. The simple switch architecture is
an implementation of the `abstract switch model` presented in the
[P4-14 Specification](https://p4.org/p4-spec/p4-14/v1.0.4/tex/p4.pdf) (the first version of the P4 language). The simple
switch target has been implemented using the `bmv2` library, which is a framework that allows developers to implement their own
software p4 targets.

In the second version of the language (P4-16, the one we use in this repository),
several backwards-incompatible changes were made to the language and syntax. In particular, a large number
of language features were eliminated from the language and moved into
libraries including counters, checksum units, meters, etc. And thus, the core of the P4-16 language has been made
very simple and advanced features that are unique to a target architecture
are now described in the so called `architecture libraries`. The `v1model` architecture (the one we import
at the beginning of every program) is the architecture library for the simple switch target. It includes the declaration
of all the standard metadata and intrinsic metadata fields, extern functions, and switch architecture (or pipeline) package
description.

The P4_16 language also now has a Portable Switch Architecture (PSA)
defined in [its own specification](https://p4.org/specs).  As of
September 2018, a partial implementation of the PSA architecture has
been done, but it is not yet complete.  It will be implemented in a
separate executable program named `psa_switch`, separate from the
`simple_switch` program described here.

In this document we will provide you important information regarding the simple
switch architecture and the v1model library.

## Standard metadata

The [`v1model.p4`](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4)
architecture defines a long list of metadata fields. Each field has a different usage,
some are writable others are read only and others are both. Some fields are populated by the switch
and give you useful information like the ingress_port, timestamps, etc. Other fields can be used to
tell the switch what to do (i.e egress_spec).

For a P4_16 program using the v1model architecture and including the
file `v1model.p4`, all of the fields below are part of the struct with
type `standard_metadata_t`.

### Standard Metadata

- `ingress_port`: For new packets, the number of the
  ingress port on which the packet arrived to the device.  Read only.
  For resubmited and recirculated packets, the ingress_port is 0.

- `egress_spec`: Can be assigned a value in ingress code
  to control which output port a packet will go to.  The v1model extern action `mark_to_drop`,
  have the side effect of assigning an implementation specific value
  to this field (511 decimal for simple_switch), such that if
  `egress_spec` has that value at the end of ingress processing, the
  packet will be dropped and not stored in the packet buffer, nor sent
  to egress processing.

- `egress_port`: Only intended to be accessed during
  egress processing, read only.  The output port this packet is
  destined to.

- `clone_spec`: should not be accessed directly. It is set by
  the `clone` and `clone3` action primitives and is required for the
  packet clone (or mirroring) feature. The "ingress to egress" clone
  primitive action must be called from the ingress pipeline, and the
  "egress to egress" clone primitive action must be called from the
  egress pipeline.

- `instance_type`: Contains a value that can be read by
  your P4 code.  In ingress code, the value can be used to distinguish
  whether the packet is newly arrived from a port (`NORMAL`), it was
  the result of a resubmit primitive action (`RESUBMIT`), or it was the
  result of a recirculate primitive action (`RECIRC`).  In egress processing,
  can be used to determine whether the packet was produced as the
  result of an ingress-to-egress clone primitive action (`INGRESS_CLONE`),
  egress-to-egress clone primitive action (`EGRESS_CLONE`), multicast
  replication specified during ingress processing (`REPLICATION`), or
  none of those, so a normal unicast packet from ingress (`NORMAL`).

  You can see the values of each instance type below, or copy this definitions
  at the beginning of your P4 code.

  ```bash
  #define PKT_INSTANCE_TYPE_NORMAL 0
  #define PKT_INSTANCE_TYPE_INGRESS_CLONE 1
  #define PKT_INSTANCE_TYPE_EGRESS_CLONE 2
  #define PKT_INSTANCE_TYPE_COALESCED 3
  #define PKT_INSTANCE_TYPE_INGRESS_RECIRC 4
  #define PKT_INSTANCE_TYPE_REPLICATION 5
  #define PKT_INSTANCE_TYPE_RESUBMIT 6
  ```

- `drop`: deprecated, not used by the simple switch.

- `recirculate_port`: deprecated, not used by the simple switch.

- `packet_length`: For new packets from a port, or
  recirculated packets, the length of the packet in bytes.  For cloned
  or resubmitted packets, you may need to include this in a list of
  fields to preserve, otherwise its value will become 0.

### Queueing Metadata

Metadata information that is populated by the switch when going from the ingress to the egress pipeline. Thus,
this metadata fields can only be accessed from the egress pipeline and they are read-only.

- `enq_timestamp`:a timestamp, in microseconds, set when the packet is first
enqueued.

- `enq_qdepth`:the depth of the queue when the packet was first enqueued.

- `deq_timedelta`: the time, in microseconds, that the packet spent in the

- `deq_qdepth`:the depth of queue when the packet was dequeued.

- `qid`: when there are multiple queues servicing each egress port (e.g. when
priority queueing is enabled), each queue is assigned a fixed unique id, which
is written to this field. Otherwise, this field is set to 0.
TBD: `qid` is not currently part of type `standard_metadata_t` in v1model.
Perhaps it should be added?

### Intrinsic Metadata

Each architecture usually defines its own intrinsic metadata fields, which are
used in addition to the standard metadata fields to offer more advanced
features. In the case of simple_switch, we have two separate intrinsic metadata
headers. These headers are not strictly required by the architecture as it is
possible to write a P4 program and run it through simple_switch without them
being defined. However, their presence is required to enable some features of
simple_switch. For most of these fields, there is no strict requirement as to
the bitwidth, but we recommend that you follow our suggestions below. Some of
these intrinsic metadata fields can be accessed (read and / or write) directly,
others should only be accessed through primitive actions.

- `ingress_global_timestamp`: a timestamp, in microseconds, set when the packet
shows up on ingress. The clock is set to 0 every time the switch starts. This
field can be read directly from either pipeline (ingress and egress) but should
not be written to.

- `egress_global_timestamp`: a timestamp, in microseconds, set when the packet
starts egress processing. The clock is the same as for
`ingress_global_timestamp`. This field should only be read from the egress
pipeline, but should not be written to.

- `lf_field_list`: used to store the learn id when calling `generate_digest`; do
not access directly.

- `mcast_grp`: needed for the multicast feature. This field needs to be written
in the ingress pipeline when you wish the packet to be multicast. A value of 0
means no multicast. This value must be one of a valid multicast group configured
through bmv2 runtime interfaces.

- `resbumit_flag`: should not be accessed directly. It is set by the
`resubmit` action primitive and is required for the resubmit
feature. As a reminder, `resubmit` needs to be called in the ingress
pipeline.

- `egress_rid`: needed for the multicast feature. This field is only valid in
the egress pipeline and can only be read from. It is used to uniquely identify
multicast copies of the same ingress packet.

- `checksum_error`: Read only. 1 if a call to the
  `verify_checksum` primitive action finds a checksum error, otherwise 0. Calls to
  `verify_checksum` should be in the `VerifyChecksum`
  control in v1model, which is executed after the parser and before
  ingress. Deprecated in favour of `parser_error`.

- `parser_error`: indicates if something wrong happened during parsing. Possible values are:

  ```bash
  error {
      NoError,           /// No error.
      PacketTooShort,    /// Not enough bits in packet for 'extract'.
      NoMatch,           /// 'select' expression has no matches.
      StackOutOfBounds,  /// Reference to invalid element of a header stack.
      HeaderTooShort,    /// Extracting too many bits into a varbit field.
      ParserTimeout      /// Parser execution time limit exceeded.
  }
  ```

- `recirculate_flag`: should not be accessed directly. It is set by the
`recirculate` action primitive and is required for the recirculate feature. As a
reminder, `recirculate` needs to be called from the egress pipeline.

Several of these fields should be considered internal implementation
details for how simple_switch implements some packet processing
features.  They are: `lf_field_list`, `resubmit_flag`,
`recirculate_flag`, and `clone_spec`.  They have the following
properties in common:

- They are initialized to 0, and are assigned a compiler-chosen non-0
  value when the corresponding primitive action is called.
- Your P4 program should never assign them a value directly.
- Reading the values may be helpful for debugging.
- Reading them may also be useful for knowing whether the
  corresponding primitive action was called earlier in the
  execution of the P4 program, but if you want to know whether such a
  use is portable to P4 implementations other than simple_switch, you
  will have to check the documentation for that other implementation.

## Externs

There are extern types, functions and objects. They are all defined in the
architecture file description [`v1model.p4`](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4).

- `counter`(bit<32> `size`, CounterType `type`): it allows you to declare an array of indirect counters, that can be increased 1 by 1.

   - void `count`(in bit<32> `index`): function that increases the counter at `index` by 1, and/or by the number of bytes in the packet.

- `direct_counter`(CounterType `type`): it allows you to declare a direct counter, that later can be referenced with a table. Each time there
is a match in the table the counter at the position of the handle entry for that match gets increased by 1, or by the number of bytes the packet
contains.

   - void count(): called automatically during the match-action of a given referenced table.

- `meter`(bit<32> `size`, MeterType type): it allows you to declare an array of indirect meters. Meters can either track packet or byte frequency.

   - void execute_meter(in bit<32> index, result): executes the meter at a given `index` and returns the status of the meter using a Colour.

- `direct_meter`(MeterType Type): it allows you to declare a direct meter, that later can be references with a table, similarly to counters, Each time that
there is a match in the table the meter at the position of the handle entry for that match gets increased by 1, or by the number of bytes the packet
contains.

   -void read(result): returns the colour for the last executed entry.

- `register`<T>(bit<32> size): it allows you to declare an array or register of size `size` and cell width of `T` (e.g bit<8>).

   - void read(result, bit<32> index): function to read the content of cell at `index`. Stores the output at the variable `result` (which must have width `T`).
   - void write(bit<32> index, value): function that write `vale` (also with width `T`) at the cell `index`.

- `random`(result, lo, hi): returns a random value between `lo` and `hi` and stores it in `result`. The three variables must have the same type (width).

- `digest`(receiver, data): function that allows you to digest small pieces
of information and send them to the controller. The channel used to send
the digested message depends on the switch architecture. In the simple
switch digest is implemented using the socket library `nanomsg`.
When using with the `simple_switch` you can set the
receiver field to `1` always. Data needs to be a `struct` that contains all
 the variables, headers, or metadata you want to digest to the controller.

- `mark_to_drop`(): simply sets the `standard_metadata.egress_spec` to a
 value that indicates the Traffic manager or end of egress to drop the packet.
 Note that, this function will no act as a `return`, meaning that if the program
 changes the `egress_spec` before leaving the `ingress` or `egress` pipeline
 the packet will not be dropped.

- `hash`(out O result, in HashAlgorithm algo, in T base, in D data, in M max):
exectures the hash algorithm `algo` over `data` and stores the output in `result`.
The output value will range between `base` and `max`. You can see the different
available algorithms at the `v1model.p4` architecture [description](https://github.com/p4lang/p4c/blob/master/p4include/v1model.p4).

- `verify_checksum`(in bool condition, in T data, inout O checksum, HashAlgorithm algo):
function to verify the integrity of the received data. If `condition` is true it computes
the hash algorithm `algo` over the struct `data` and compares the value with `checksum`. It
then stores the output in `standard_metadata.checksum_error` (0 for valid, 1 for invalid).

- `update_checksum`(in bool condition, in T data, inout O checksum, HashAlgorithm algo):
function that allows you to update checksum fields after modifying some of
the fields involved during the calculation. If `condition` is true, the `data` struct
is hashed using the `algo` algorithm and stored in the `checksum` field of
your choice. For example the `ipv4.checksum` field.

- `verify_checksum_with_payload`: same than `verify_checksum` but includes
the packet payload after `data`.

- `update_checksum_with_payload`: same than `update_checksum` but includes
the packet payload after `data`.

- `resubmit`(in T data): resubmits the original packet to the parser. It can be applied only at the ingress. At the
end of the ingress the `original` packet (modifications will not be present)
will be submitted again to the parser, however all the fields added in the `data`
parameter will keep the value they had at the end of ingress from the `original` packet.
If multiple resubmit actions get executed on one packet, only the field
list from the last resubmit action is used, and only one packet is resubmitted.

- `recirculate`(in T data): recirculates the modified packet to the ingress. It can be applied only at
the egress. This function marks the packet to be recirculated after egress deparsing, meaning that
all the changes made to the packet will be kept in the recirculated one. Similarly
to resubmit, some metadata fields can be kept using the `data` parameter.

- `clone`(in CloneType type, in bit<32> session): this functions allows you
to create packet clones. For more information see its specific section [below](#cloning-packets).

- `clone3`(in CloneType type, in bit<32> session, in T data): same than `clone` but allows you
to copy some metadata fields to the cloned packet.

- `truncate`(in bit<32> length): function that allows you to truncate packets
at the egress. The packet will only keep the amount of bytes you specify
in the `length` parameter.  It can be executed at the ingress or egress, however
it will only have effect during deparsing.

## Advanced Features Examples

In this section we explain how to use some of the most advanced features the simple switch provides. Most of them involve
p4 code and control plane programming.

### Creating Multicast Groups

In order to use the packet replication engine of the simple switch several things need to be done both in the p4 program and
using the runtime interface or CLI.

First of all you need to create multicast groups, multicast nodes and associate them to ports and groups. That can be done using
the `simple_switch_CLI` or the thrift SimpleSwitchAPI provided by `P4 utils`:

1. Create a multicast group:

   ```
   mc_mgrp_create <id>
   ```
2. Create a multicast node with a Replication id (rid)

   ```
   mc_node_create <rid> <port_number>
   ```

   This function returns a `handle_id` which is some kind of identifier that needs to be used when associating the node with the multicast group. By default
   the returned `handle_id` will be 0 for the first node we create, 1 for the next, and so on. Thus, we just have to remember in which order we added them. Note that
   the `rid` and the `handle_id` are not the same. The `rid` can be set to the same for each node you create, and it is simply and identifier that will be attached to
   every packet that gets multicasted using this `mc_node`. That value can be found at the egress by reading `standard_metadata.egress_rid`.


3. Assign node with multicast group:

   ```
   mc_node_associate <mcast_grp_id> <node_handle_id>
   ```

In the following example we will associate port 1,2 and 3 to the same multicast group using the `CLI`
(translation to SimpleSwitchAPI is one to one):

```
mc_mgrp_create 1

mc_node_create 0 1
mc_node_create 0 2
mc_node_create 0 3

mc_node_associate 1 0
mc_node_associate 1 1
mc_node_associate 1 2
```

Alternatively, you can create nodes with multiple ports as follows:

```
mc_mgrp_create 1
mc_node_create 0 1 2 3
mc_node_associate 1 0
```

Finally, once you have programmed the replication engine and added multicast groups you can use them in your P4 program. For that
you need to write the value of the multicast group id you want to use for multicasting in the `standard_metadata.mcast_grp` during the
ingress pipeline. Following our example, to send a packet to ports 1, 2 and 3 we would `standard_metadata.mcast_grp = 1`.



### Cloning Packets

Cloning/mirroring packets is a very common switch feature. Cloning is used in order to create packet
replicas and send them somewhere else. This can be used for monitoring, to send data to a control plane, etc.

The simple switch provides two `extern` functions that can be used to clone packets:

* `clone(in CloneType type, in bit<32> session)`
* `clone3<T>(in CloneType type, in bit<32> session, in T data)`

1. The first parameter in both externs is the type, simple switch allows two types `CloneType.I2E`, and
`CloneType.E2E`. The first type can be used to send a copy of the original packet to
the egress pipeline, the later sends a copy of the egress packet to the buffer mechanism.

2. The second parameter is the `mirror id or session id`. The mirroring ID is used by the switch to know
to which port the packet should be cloned to. This mapping needs to be configured using the control plane API or CLI doing the following:

    ```
    mirroring_add <session> <output_port>
    ```

3. When using `clone3` you can add as a third parameter a metadata `struct`. When a packet is cloned all its metadata fields
are reset to the default value (usually 0). When using `clone3` you can tell the switch to copy some metadata values so the cloned packet
will be able to access them.


For example, lets say we want to send a copy of every packet to a controller that is listening at port number `7`, to do what
we would:

1. Add mirroring session using the CLI or API:

   ```
   mirroring_add 100 7
   ```

2. Use clone extern in the p4 code (during the ingress pipeline):

   ```
   clone(CloneType.I2E, 100)
   ```

3. The packet will be cloned to the egress pipeline. To differentiate between a normal packet and a cloned one you need to use
the `standard_metadata.instance_type` field (see above in the documentation). For packets cloned from the ingress pipeline, the
`instance_type == 1`.


### Packet Digests

The simple switch target provides a way to send some small information (digests) to a controller
by using the `digest` extern.

Digest packets are sent in addition to the original packet, and thus there is no need to clone anything.
So, for example, in the typical L2 learning case you would still want to forward a packet
that missed the Source MAC lookup, while at the same time send a notification to the control plane.

Simple switch digests are implemented using the socket library [Nanomsg](https://nanomsg.org/).

The `digest` extern must be called from the ingress pipeline. And example follows:

Lets say we have this metadata struct defined in our p4 code:

```
struct digest_data_t {

    bit<8> a;
    bit<8> b;

}

struct metadata {
    /* empty */
    digest_data_t digest_data;
}
```

Then we can call digest in the ingress pipeline:

```
digest(1, meta.digest_data); //assume that metadata is called meta in the ingress parameters
```

> Note that the first parameter of digest is always 1.

Receiving digested packets is not trivial, since the switch adds some control header that needs to be
parsed, furthermore, for each digested packet, the switch expects an acknowledgement message (used to filter duplicates).


## Using Strict Priority Queues

Simple switch allows the use of multiple queues per output port. However, in order to use them you will need to do some small modifications.

1. Uncomment `#define SSWITCH_PRIORITY_QUEUEING_ON` in the `bmv2/targets/simple_switch/simple_switch.h`.
2. Add this two metadata fields to the `v1model.p4` file:

    ```
    //Priority queueing
    @alias("queueing_metadata.qid")           bit<5>  qid;
    @alias("intrinsic_metadata.priority")     bit<3> priority;
    ```

    You can get the `v1model.p4` file from the `p4c` repo or in `p4c/p4include/v1model.p4`.

3. Copy the modified `v1model.p4` file to `/usr/local/share/p4c/p4include/`:

    ```bash
    cp v1model.p4 /usr/local/share/p4c/p4include/
    ````

4. Recompile the `bmv2` so the multiple queues are added

By default you will have 8 strict priority queues, being 0 the highest priority and 7 the lowest. Packets in a higher priority queue will always be
transmitted before than packets in a lower priority queue.

To select the queue you want to use for your packets you need to set the `standard_metadata.priority` field to `0-7`.

If needed you can individually configure the rate and the length of each queue. In order to do that you will have to modify the `simple_switch` code. I you
want to do this ask and we can show you how to do it.

## Ingress and Egress Pipelines

We have seen that packets can be processed in a wide range of manners. Depending if we want to unicast, multicast, clone, digest, resubmit or recirculate a packet
can be processed differently. Also you might ask yourself what happens if we try to unicast and multicast at the same time, or resubmit and recirculate. In this section
we explain how does simple switch handles those cases at the ingress and egress pipelines.

In order to understand how things are executed you have to check the
[`simple_switch` implementation](https://github.com/p4lang/behavioral-model/blob/master/targets/simple_switch/simple_switch.cpp).

### Ingress Pipeline

In this section we will show what happens to packets after all the logic from the ingress control has been executed.

1. If `clone` or `clone3` were called, the packet will be cloned to the `egress_port` you specified using the mirroring
id (for more information see the [cloning section](#cloning-packets)). This copies the ingress packet to egress pipeline without
all the ingress control modifications. If `clone3` action is used, the packet will also preserve the metadata fields specified. Finally, it
will get the `standard_metadata.instance_type` modified to the corresponding value.

2. If there was a call to `digest` the switch will send a control plane message with the specified fields to the controller.

3. The first two conditions can be executed in parallel. Now we will show some actions that are mutually exclusive, thus if one occurs
the other can not happen. Furthermore, the order in which we show them here matter. Only the first true condition is executed by the switch.

   1. Resubmit: If resubmit was called the packet will be send to the ingress control again with the original packet values and metadata fields.
   You can preserve some fields by passing them to the resubmit action.
   2. Multicast: If the `standard_metadata.mcast_grp` field was set during the ingress, the packet is copied n times depending on how you configured the switch
   using the control plan API (see more in the [multicast section above](#creating-multicast-groups)).
   3. Drop: If the `egress_port==511 or 0` the packet gets dropped. You can do that by calling the `mark_to_drop` action or by directly assigning those values
   to the `egress_port` field.
   4. Unicast: If non of the above is true, the packet is queued at the `egress_spec` port queues.


### Egress Pipeline

In this section we will show what happens to packets after all the logic from the egress control has been executed.

1. If `clone` or `clone3` were called in the egress pipeline, the packet will be cloned to the `egress_port` you specified using the mirroring
id (for more information see the [cloning section](#cloning-packets)). This will send a copy of the egress packet to the egress control block,
with the egress metadata unless specified with `clone3`.

2. Now we will show some actions that are mutually exclusive, thus if one occurs
the other can not happen. Furthermore, the order in which we show them here matter. Only the first true condition is executed by the switch.

   1. Drop: if you call `mark_to_drop` during the egress pipeline the packet will be directly dropped at the end of the pipeline.
   2. Recirculate: if you called the `recirculate` action the packet will be sent to the ingress pipeline again, with the packet as constructed by the
   deparser (you can add or remove headers). The packet will preserve the fields specified.
   3. Send Packet Out: the packet goes out to the interface.
