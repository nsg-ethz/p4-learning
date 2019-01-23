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

```
sudo p4run
```


Start the receiver script at `h2`:
```
mx h2
python receive.py
```


Send packets with Ipv4 Options header prepared:
```
mx h1
python send.py 10.0.2.2 "hi h2"
```