# Debugging and Troubleshooting

### Monitoring Traffic

Sniffing traffic can be a very powerful tool when debugging your P4 program. Basic things like verifying
if traffic crosses certain path, or if header fields look like expected can be easily achieved by just
observing traffic. For that, there is a wide range of tools that can be used:

#### Pcap Files:

The `simple_switch` provides an option to save all the traffic that crosses its interfaces in a pcap file. To
enable pcap logging when starting your switch, use the `--pcap=<output_dir>` command line option. For Example:

```bash
sudo simple_switch -i 0@<iface0> -i 1@<iface1> --pcap=<output_dir> <path to JSON file>
```

Pcap logging will create several files using the following naming: `<sw_name>-<intf_num>_<in|out>.pcap`.

**P4 Utils Integration**:

If you enable pcap in the `p4app.json` configuration file, switches will be started with the `--pcap` option and use as output dir `./pcap`.

#### Wireshark/Tshark:

Another option is to observe the traffic as it flows. For that you can use tools like `tshark` and its GUI version `wireshark`. Wireshark
is already installed in the VM, you can find its executable in the desktop.

To capture traffic with tshark run:

```bash
sudo tshark -i <interface_name>
```

#### Tcpdump:

Similarly, and if you prefer, you can use `tcpdump` (also already installed in the VM).

To capture traffic with tcpdump run (shows link-layer information and does not resolve addresses):

```bash
sudo tcpdump -l -enn -i <interface_name>
```

### Logging

To enable logging, make sure that you enabled `--with-nanomsg` flag to `configure` before compiling `bmv2`.

#### Console logging

To enable console logging when starting your switch, use the `--log-console` command line option. For example:

```bash
sudo simple_switch -i 0@<iface0> -i 1@<iface1> --log-console <path to JSON file>
```

This will print all the messages in the terminal. Since this is not the most convenient, you can always redirect
it to a log file:

```bash
sudo simple_switch -i 0@<iface0> -i 1@<iface1> --log-console <path to JSON file> >/path_to_file/sw.log
```

#### P4 Utils Integration

If you enable logging in the `p4app.json` configuration file, switches will automatically write all the console logging
into a file in the `./log` directory and with `<sw_name>.log`.

#### CLI logging

If logging is enabled, and you use the `simple_switch_CLI` when starting the topology (with `p4utils`) the output
of the `cli` will be also logged in the log folder under the name `<sw_name>_cli_output.log`

#### Event logging

To enable event logging when starting your switch, use the *--nanolog* command
line option. For example, to use the ipc address *ipc:///tmp/bm-log.ipc*:

    sudo ./simple_switch -i 0@<iface0> -i 1@<iface1> --nanolog ipc:///tmp/bm-log.ipc <path to JSON file>

Use [tools/nanomsg_client.py](https://github.com/p4lang/behavioral-model/blob/master/tools/nanomsg_client.py) as follows when the
switch is running:

    sudo ./nanomsg_client.py [--thrift-port <port>]

The script will display events of significance (table hits / misses, parser
transitions, ...) for each packet.

When using `P4 utils` to create the topology, each switch will automatically get assigned with a
`thrift-port`. There are several ways to find the mapping between switch and port, but the easiest is
to check the `print` messages displayed by `p4run`. Try to find a line that looks like:

```bash
s1 -> Thrift port: 9090
```

### Debugger

To enable the debugger, make sure that you passed the `--enable-debugger` flag
to `configure`. You will also need to use the `--debugger` command line flag
when starting the switch.

Use [tools/p4dbg.py](https://github.com/p4lang/behavioral-model/blob/master/tools/p4dbg.py) as follows when the switch is running to
attach the debugger to the switch:

    sudo ./p4dbg.py [--thrift-port <port>]

You can find a P4 debugger user guide in the bmv2
 [docs](https://github.com/p4lang/behavioral-model/blob/master/docs/p4dbg_user_guide.md).

### Attaching Information to a Packet

Some times you do not want to use the logging system or debugger, or basically they are disabled. Yet, you could still
get some insights on what the code does by just modifying a header field depending on which part of the code
gets executed and check that value when the packet leaves the switch. Of course you can do something more sophisticated, and
and use several fields, read the value of a register and save it in the header, and so on.


### Using P4 tables to inspect headers/metadata values

We already have an [example](../examples/debugging_table/README.md) covering this. Basically the idea is to use
P4 tables and do an `exact` match to all the fields you want to track. Every time the table is executed, if the bmv2
debugging is enabled, the switch will write the values of each field that was used to match the table entry in the switch
log file. See the example for more information.

### If the above did not solve your problem:

P4, and all the tools around are quite new. Several times things just do not work
because there is a bug in the compiler or in the software switch implementation.

1. First of all, check what the [P4-16 specification](https://p4.org/p4-spec/docs/P4-16-v1.0.0-spec.html) says about that. The specification
is quite generic and not always will be able to give you a direct answer about what should be
the expected behaviour of some 'Action', since the answer can be completely related to what a
specific switch implementation does (in our case the bmv2 simple switch).

2. Check the `p4-org` mailing list. Probably you are not the first one having this problem, and someone
already asked what you need in the mailing list. A good trick to get only results from the mailing list when
googling them is to write your query as follows : `site:http://lists.p4.org/ <query>`. If you type in google
`site:http://lists.p4.org/ "simple_switch"` you will get all the threads where the word `simple_switch` appears.

3. Check the `github` issues section of [`bmv2`](https://github.com/p4lang/behavioral-model/issues)
and [`p4c`](https://github.com/p4lang/p4c/issues) repositories. By default the searching bar adds a `is:issue is:open`
filter, you can just remove it and write a `keyword` to find information about the issue and how to solve it.

4. If you do not find the solution anywhere, you can write in the mailing list yourself, or open an issue
in github.
