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

In the past to enable multiqueueing one had to uncomment something in the `bmv2`
model code and recompile. A recent pull request
[PR](https://github.com/p4lang/behavioral-model/commit/adff022fc8679f5436d07e7af73c3300431df785)
improved this part, and now multiqueueing can be directly enabled from the
`simple_switch` command line, using the target argument `--priority-queues
<num>`.

In order to fully utilize priority queues, we need two medatata fields to be
present in the `v1model.p4` architecture definition. If the fields `priority`
and `qid` are not present in the `standard_metadata_t` at the
[v1model.p4](https://github.com/p4lang/p4c/blob/main/p4include/v1model.p4#L64)
you have to manually add them:

1. Go to the directory where you have downloaded `p4c`.
2. Copy and edit `PATH_TO_P4C/p4include/v1model.p4` in another location. You
   will have to add the following metadata fields inside the `standard_metadata`
   struct (if not already present). You can find an already configured
   `v1model.p4` in this directory.
    ``` 
    /// set packet priority
    @alias("intrinsic_metadata.priority")
    bit<3> priority;
    @alias("queueing_metadata.qid")
    bit<5> qid;
    ```
3. Copy the updated `v1model.p4` to the global path `/usr/local/share/p4c/p4include/`. Remember that every time you update `p4c` this file will be overwritten and the metadata fields might be removed. 


Alternatively you can use the provided [v1model-mod.sh]()./v1model-mod.sh script which does all that automatically:
```
./v1model-mod.sh
```

At this point everything should be set to start using strict priority queues in the `simple_switch`
    

## How to run

First of all, in order to enable `multiqueueing` at the `simple_switch` we need
to add the option either in the `p4app.json` or in the `network.py` script. You
can see that that can be achieved as follows:

In `p4app.json`:

```json
    "s1": {
    "cli_input": "s1-commands.txt",
    "priority_queues_num": 8
    }
```

In the `network.py` network script:

```python
# Network definition
net.addP4Switch('s1', cli_input='s1-commands.txt')
net.setPriorityQueueNum('s1', 8)
```

Running the code:

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

You will observe that the first flow will not get through the switch during the
10 seconds in which the second one is active, because the latter will get all
the available bandwidth according to its higher priority.

Furthermore, you can use the script [set_queue_rates.py](./set_queue_rates.py)
to modify the rate each priority queue has. The rate unit that `simple_switch`
uses is the packet per second or pps.