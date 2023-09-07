# Heavy Hitter Detection

```
                   +--+
                   |h4|
                   ++-+
                    |
                    |
+--+      +--+     ++-+     +--+
|h1+------+s1+-----+s3+-----+h3|
+--+      +-++     +--+     +--+
            |
            |
          +-++
          |s2|
          +-++
            |
            |
          +-++
          |h2|
          +--+
```

## Introduction

Uses a counting bloom filter to block flows for which the switch has observed more than
a certain number of packets (default 1000).


## How to run

Run the topology:

```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Run the receiver and the sending scripts in `h2` and `h1` respectively:

```bash
mx h2
python receive.py
```

Send 1500 packets from `h1` to `h2`. Only the first 1000 will be received.

```bash
mx h1
python send.py 10.0.2.2 1500
```


