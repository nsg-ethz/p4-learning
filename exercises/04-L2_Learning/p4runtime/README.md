# L2 Learning

## Introduction

This is the last exercise of our `Basic L2 Switch` series. In the first exercise we implemented a very
basic l2 forwarding switch, then in the second exercise we made the switch a bit more realistic and added
the feature of forwarding packets for unknown and broadcast destinations.

<p align="center">
<img src="images/l2_topology.png" title="L2 Star Topology">
<p/>

In this exercise we will add the cherry on the cake. We will make the switch a bit smarter and add to it the
capability of learning MAC addresses to port mappings autonomously, as a regular L2 switch would do. Thus,
we will not need to add manually the `mac_address` to `output_port` mapping as we were doing in the previous
exercises. Instead, now we will leave that table empty, and will let the switch (with the help of a controller)
fill it automatically.

L2 learning works as follows:

1. For every packet the switch receives, it checks if it has seen the `src_mac` address before. If its a new mac address,
it sends to the controller a tuple with (mac_address, ingress_port). The controller receives the packet and adds two rules
into the switch's tables. First it tells the switch that `src_mac` is known. Then, in another table it adds an entry to map
the mac address to a port (this table would be the same we used in the previous exercises).

2. The switch also checks if the `dst_mac` is known (using a normal forwarding table), if known the switch forwards
the packet normally, otherwise it broadcasts it. This second part of the algorithm has been already implemented in the previous
exercise.

In this exercise we will implement a learning switch. For that we need a controller code, and instruct the switch
to send the (mac, port) tuple to the controller. For the sake of learning, we will show you two different
ways of transmitting information to the controller: cloning packets to the controller (`cpu`) or sending digest messages.

## Before Starting

For this exercise the files we provide you are:

- `p4app_cpu.json` and `p4app_digest.json`: two p4 utils configuration files. They define the same star topology used in previous exercises. `p4app_cpu.json` and `p4app_digest.json`: two p4 utils configuration files. They define the same star topology used in previous exercises.
- `network_cpu.py` and `network_digest.py`: *P4-Utils* topology initilization scripts that can be used instead of the JSON configuration files to run the network.
- `p4src/l2_learning_copy_to_cpu.p4` and `p4src/l2_learning_digest.p4`: p4 program skeletons. Each skeleton will be used for one version
  of the solution.
- `l2_learning_controller.py`: since there is not much documentation on how to write controllers with P4 utils, we provide you some useful
  skeleton that you just have to fill with the l2 algorithm.

#### Notes about p4app.json

Unlike in previous exercises, for this exercise we do not need the automatic ARP table population at each host.
Actually, during this exercise we want to disable this feature. Once our switches get the feature of broadcasting
packets ARP requests will be sent everywhere and thus ARP tables will be filled without any problem.

To disable automatic ARP population we added the following line to the `topology` section of the `p4app.json`:

```
"auto_arp_tables": false
```

To disable automatic ARP population we added the following line in the Python scripts:
```python
net.disableArpTables()
```

Note that `p4app_cpu.json` adds a `cpu_port: true` option to `s1`. This will make P4-Utils add an extra port to `s1`, this port then will be used by the controller to receive control plane packets. The same is done in `network_cpu.py` with the option `net.enableCpuPortAll()`.

**Note:** This option is already enabled in the provided configuration files.

Furthermore, during this exercise you will need to use the `--conf` option when calling `p4run`. By default, if you do not specify
anything it tries to find a configuration file named `p4app.json`, which has to be located in the same path. Since in this exercise we
provided you with two different configuration files you will have call it as follows:
```bash
sudo p4run --conf <json conf file>
```

On the other hand, if you want to use the Python script to initialize the network, simply run:
```bash
sudo python <script path>
```

You can find all the documentation about `p4app.json` in the *P4-Utils* [documentation](https://nsg-ethz.github.io/p4-utils/usage.html#json).


## Implementing L2 Learning

For this exercise we will also use two different techniques, as described above. Since the learning switch also need to
flood unknown packets you will be able to reuse code from the previous exercise (however, all the steps will be listed in the
`TODOS`).

#### Learning Switch: cloning packets to the controller

To complete this exercise we will need to clone packets. When a learning packet needs to be sent to the controller the switch
will have to make a copy of the packet, send it to the controller, and then continue the pipeline normally with the original packet.
In order to help you with the cloning part, a section in the new `Simple Switch` documentation explains how to clone packets
using the simple switch target.

Your tasks are:

1. Read the [documentation section](https://github.com/nsg-ethz/p4-learning/wiki/BMv2-Simple-Switch#cloning-packets) that talks about packet cloning.

2. Define a `cpu_t` header that will be added to our original packet. This header needs two fields, one for the source mac address,
and one for the input port (48 and 16 bits respectively). Remember to cast the `standard_metadata.ingress_port` before assigning it to this header field (the
standard metadata field is 9 bits, but we need to send a multiple of 8 to the controller, and thus we use 16 bits).

3. Cloned packets get all the metadata reset. If we want to be able to know the `ingress_port` for our cloned packet we will need to put
that in a metadata field. Make sure you tag the field with the `@field_list`. The user metadata fields that are tagged with @field_list(index) will be sent to the parser together with the packet. For more info read the docs section from `TODO 1`

4. Add the new header to the headers struct.

5. Define a normal forwarding table, and call it `dmac`. The table should match to the packet's destination mac address, and
call a function `forward` that sets the output port. Set `NoAction` as default. Copy this from the previous exercise.

**Note:** The naming of these tables and actions needs to match the names you use in the controller code *precisely*.

6. Define a table named `broadcast` that matches to `ingress_port` and calls the action `set_mcast_grp` which sets the
multicast group for the packet, if needed. Define also the `set_mcast_grp` action. Copy this from the previous exercise.

7. Define a third and new table (and name it `smac`). This new table will be used to match source mac addresses. If there
is a match nothing should happen, if there is a miss, an action `mac_learn` should be called. The `mac_learn` action should
set the metadata field you defined in 3 to `standard_metadata.ingress_port` and call `clone_preserving_field_list` with `CloneType.I2E` and  mirroring session ID = 100, with the `fiel_list_index` assinged at the defined metadata field `ingress_port`. Again for more info refer to the cloning documentation or the [comments in the v1model](https://github.com/p4lang/p4c/blob/main/p4include/v1model.p4#L607C1-L607C1).


8. Write the apply logic. First apply the `smac` table. Then the `dmac` and if it does not have a hit, apply the `broadcast` table.

9. When you call `clone_preserving_field_list` the packet gets copied to the egress pipeline. Here you have to do several things.

   * First check that the `instance_type` is equal to 1 (which means that the packet is an ingress clone).
   * Now you will use the `cpu` header you defined in 2 to add the learning information we want to send to the controller. To
    enable the header you need to set it valid using `setValid()`.  Fill the `cpu` headers fields with the mac source port and
    ingress_port.
   * Finally set the `hdr.ethernet.etherType` to `0x1234`. The controller uses to filter packets.

10. Emit the new header you created (only valid headers are put back to the packet).

11. Implement the controllers learning function:

    At this point you will have your P4 program ready. Now is time to implement the controller.  However, since we did not explain
    how to write controller code using the P4 utils library we will provide you an almost complete solution. You will only need to implement
    a function called `learn`. The controller will handle automatically for you the following:

    1. Reset the switch state.
    2. Add Broadcast groups automatically.
    3. Add the mirror session ID and map it to the `CPU_PORT`.
    4. It will listen for `learning` packets and will parse them.

    Look for the `learn` function in the controller program `l2_learning_controller.py`. The function learn will be automatically called
    by the controller when the switch sends a packet to it. As a parameter it receives a list of tuples with (src_macs, ingress_ports). Use the
    method `self.controller.table_add()` to populate the `smac` and `dmac` tables accordingly. The `table_add` does the same than the CLI `table_add`
    command line.

#### Testing your solution

Once you have the `l2_learning_copy_to_cpu.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).
   ```bash
   sudo p4run --conf p4app_cpu.json
   ```
   or
   ```bash
   sudo python network_cpu.py
   ```

2. Start the controller in another terminal window:

   ```bash
   sudo python l2_learning_controller.py s1 cpu
   ```

   We tell the controller from which switch listen from. The `cpu` parameter tells the controller which technique it should
   use to receive packets. In this case, sniffing an ethernet port.

3. Ping between all hosts using the cli, and check that you have complete connectivity:

   ```
   mininet> pingall
   *** Ping: testing ping reachability
   h1 -> h2 h3 h4
   h2 -> h1 h3 h4
   h3 -> h1 h2 h4
   h4 -> h1 h2 h3
   *** Results: 0% dropped (12/12 received)
   ```

4. Verify (in a bash shell) that the switch table was populated:

   ```bash
   simple_switch_CLI --thrift-port 9090
   Obtaining JSON from switch...
   Done
   Control utility for runtime P4 table manipulation
   RuntimeCmd: table_dump dmac
   ```

#### Learning Switch: using packet digest

Now we will solve the same exercise but using the `extern` digest. To do this you should be able to reuse a big part of the `copy_to_cpu` solution.

Your tasks are:

1. Read the simple switch digest [documentation](https://github.com/nsg-ethz/p4-learning/wiki/BMv2-Simple-Switch#packet-digests) section.

2. Define a `struct` variable with a mac source address and ingress_port fields (48 and 16 bits respectively). Originally the `ingress_port` field is 9 bits, you will have to cast
it to 16 bit so the controller can decode it.

3. Add the newly created struct into the metadata fields.

4. Copy the ingress pipeline from the previous exercise. This time you only need to modify the `mac_learn` action. Now instead of cloning the
packet you need to save the (src_mac_address, ingress_port) into the metadata struct you created in 2. And then digest the packet, as explained in the
documentation.

5. Copy the ingress control logic from the previous exercise.

#### Testing your solution

Once you have the `l2_learning_digest.p4` program finished you can test its behaviour:

1. Start the topology (this will also compile and load the program).
   ```bash
   sudo p4run --conf p4app_digest.json
   ```
   or
   ```bash
   sudo python network_digest.py
   ```

2. Start the controller in another terminal window:
   ```bash
   sudo python l2_learning_controller.py s1 digest
   ```

   We tell the controller from which switch listen from. The `digest` parameter tells the controller which technique it should
   use to receive packets. In this case it will use the `nanomsg` socket to receive digests.

From now you can do the same than in the previous section.

#### Notes about the controller

Even though we provide you with the controller code almost finished, you should
make the effort and try to understand it. This controller code has some good examples of how to receive CPU packets,
how to receive digested packets, how to populate tables, how to automatically add the multicast groups, etc.

The implementation of the controller heavily uses two features from `p4-utils`. The `Topology` object and the `SimpleSwitchThriftAPI` object:

1. Topology object: when a topology is created with `p4run` all the useful topology information is encoded in a the `topology.json` file which can be
then loaded by the p4-utils `Topology` object. Using this object you can get rich information about the topology. To check when is this object used
in the controller's code look for `self.topology`. Documentation regarding this will be released soon.

2. SimpleSwitchThriftAPI: the simple switch API is python object that connects to a switch `thrift` server and provides you a Python API that is able
to do the same than the `simple_switch_CLI`. However, the advantage here is that you can dynamically read, add and modify entries in the switch without
having to use a CLI.

#### Testing your solution with multi switch topologies

If you managed to finish the above exercises, now you can test your solution with bigger networks (they must not contain loops). Build
a topology with several switches and run a controller for all of them, you should also be able to ping amongst all hosts.

#### Some notes on debugging and troubleshooting

We have added a [small guideline](https://github.com/nsg-ethz/p4-learning/wiki/Debugging-and-Troubleshooting) in the documentation section. Use it as a reference when things do not work as
expected.
