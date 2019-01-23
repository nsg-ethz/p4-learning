# Strict Priority Queueing

```

+--+      +--+     ++-+
|h1+------+s1+-----+h3+
+--+      +-++     +--+
            |
            |
          +-++
          |h2|
          +-++

```


### Introduction

To make this example work you will first need to make a small change to the `bmv2` code,
then recompile it again. At the time  of writing this, the `v1model.p4` architecture
file does not include the needed metadata to set and read the priority queues,
thus you will also have to add that in the `v1model.p4` file.

1. Go to the directory where you have `bmv2` installed. Go to `PATH_TO_BMV2/targets/simple_switch/simple_switch.h`.
look for the line `// #define SSWITCH_PRIORITY_QUEUEING_ON` and uncomment it.
2. Compile and install bmv2 again.
3. Copy and edit  `PATH_TO_P4C/p4include/v1model.p4` in another location. You will have to add the following metadata
fields inside the `standard_metadata` struct. You can find a `v1model.p4` with that added already in this directory.

    ``` //Priority queueing
        @alias("queueing_metadata.qid")           bit<5>  qid;
        @alias("intrinsic_metadata.priority")     bit<3> priority;
    ```
4. Copy the `v1model.p4` to the global path: `cp v1model.p4 /usr/local/share/p4c/p4include/`. Remember that every time you update
`p4c` this file will be overwritten and the metadata fields might be removed.
5. Now you are ready to go and test the simple_switch strict priority queues!


## How to run

Packets from h1 and h2 towards h3 will be sent to two different priority queues 0 and 7.  To
see that one queue gets priority over the other we can start to iperf sessions and see who gets
the bandwidth.

```
sudo p4run
```

Start to iperf servers at `h3`:
```
mx h3
iperf -s -p 5000 -u -i 1
iperf -s -p 5001
```

Send a UDP flow from `h1`:
```
mx h1
iperf -c 10.0.1.3 -i 1 -t 10 -p 5000 -u -b 50M
```

Send a TCP flow from `h2`:
```
mx h1
iperf -c 10.0.1.3 -i 1 -t 10 -p 5001
```

