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

1. Go to the directory where you have downloaded `bmv2`. 
2. Go to `PATH_TO_BMV2/targets/simple_switch/simple_switch.h`.
3. Look for the line `// #define SSWITCH_PRIORITY_QUEUEING_ON` and uncomment it.
4. Compile and install `bmv2` again.
5. Go to the directory where you have downloaded `p4c`.
6. Copy and edit `PATH_TO_P4C/p4include/v1model.p4` in another location. You will have to add the following metadata fields inside the `standard_metadata` struct (if not already present). You can find an already configured `v1model.p4` in this directory.
    ``` 
    /// set packet priority
    @alias("intrinsic_metadata.priority")
    bit<3> priority;
    @alias("queueing_metadata.qid")
    bit<5> qid;
    ```
7. Copy the updated `v1model.p4` to the global path `/usr/local/share/p4c/p4include/`. Remember that every time you update `p4c` this file will be overwritten and the metadata fields might be removed. As an alternative, you can copy the preconfigured `v1model.p4` in the global path.
    ```
    sudo wget https://raw.githubusercontent.com/nsg-ethz/p4-learning/master/examples/multiqueueing/v1model.p4 -O /usr/local/share/p4c/p4include/v1model.p4
    ```
8. Now you are ready to go and test the `simple_switch` strict priority queues!


## How to run

Packets from `h1` and `h2` towards `h3` will be sent to two different priority queues 0 and 7, respectively. To see that one queue gets priority over the other we can start to iperf sessions and see who gets the bandwidth.

```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Start to iperf servers at `h3`:
```bash
mx h3
iperf -s -p 5000 -u -i 1
iperf -s -p 5001 -u -i 1
```

Send a 50 Mbps UDP flow from `h1` to `h3` that lasts 60 seconds:
```bash
mx h1
iperf -c 10.0.1.3 -i 1 -t 60 -p 5000 -u -b 50M
```

Send a 50 Mbps UDP flow from `h2` to `h3` that lasts 10 seconds:
```bash
mx h2
iperf -c 10.0.1.3 -i 1 -t 10 -p 5001 -u -b 50M
```

You will observe that the first flow will not get through the switch during the 10 seconds in which the second one is active, because the latter will get all the available bandwidth according to its higher priority.