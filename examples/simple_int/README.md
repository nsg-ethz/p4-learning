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
python send.py 10.0.2.2 "test" 1
```

At the receiver you should observe something like:
```
sniffing on h2-eth0
got a packet
###[ Ethernet ]### 
  dst       = 00:00:0a:00:02:02
  src       = 00:01:0a:00:02:02
  type      = IPv4
###[ IP ]### 
     version   = 4
     ihl       = 8
     tos       = 0x0
     len       = 44
     id        = 1
     flags     = 
     frag      = 0
     ttl       = 62
     proto     = udp
     chksum    = 0x62be
     src       = 10.0.1.1
     dst       = 10.0.2.2
     \options   \
      |###[ INT ]### 
      |  copy_flag = 0
      |  optclass  = control
      |  option    = 31
      |  length    = 12
      |  count     = 2
      |  \int_headers\
      |   |###[ SwitchTrace ]### 
      |   |  swid      = 2
      |   |  qdepth    = 0
      |   |  portid    = 1
      |   |###[ SwitchTrace ]### 
      |   |  swid      = 1
      |   |  qdepth    = 0
      |   |  portid    = 2
###[ UDP ]### 
        sport     = 4321
        dport     = 1234
        len       = 12
        chksum    = 0xeb46
###[ Raw ]### 
           load      = 'test'
```