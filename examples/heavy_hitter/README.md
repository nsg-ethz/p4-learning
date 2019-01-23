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

```
sudo p4run
```

Run the receiver and the sending scripts in `h2` and `h1` respectively:

```
mx h2
python receive.py 5000
```

Send 1500 packets using the same 5-tuple. Only the first 1000 will be received by `h2`.

```
mx h1
python send.py 10.0.2.2 5000 1500
```


