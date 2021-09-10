# Simple Int

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

This example uses the Ipv4 options header to store per hop statistics such as switch id, queue depth, output port. In order to be ale to
deparse the Options header use the `receiver.py` script.

## How to run

Run the topology:
```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Start the receiver script at `h2`:
```bash
mx h2
python receive.py
```

Send 1 packet with Ipv4 Options header prepared:
```bash
mx h1
python send.py 10.0.2.2 "hi h2" 1
```