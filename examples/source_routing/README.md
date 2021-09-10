# Source Routing

```
                 
                   
                   +--+
            +------+s2+------+
            |      +--+      |
+--+      +-++              ++-+       +--+
|h1+------+s1|              |s4+-------+h2|
+--+      +-++              ++-+       +--+
            |                |
            |      +--+      |
            +------+s3+------+
                   +--+

         
```

## Introduction

In this example we will show how source hosts can add some custom headers
to instruct switches how to route packets in the network. For that we will
use header stacks and remove one header at each hop.

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


Send packets with the source routing header indicating which path the packet has
to take. Once you start the script it will ask you which path do you want to take.

You can decide to go to `h2` through `s2` and `s4`:

```bash
mx h1
python send.py 10.0.4.2
Type space separated switch_ids nums (example: "2 3 2 2 1") or "q" to quit: 2 4
```

Or you can use `s3` instead:

```bash
python send.py 10.0.4.2
Type space separated switch_ids nums (example: "2 3 2 2 1") or "q" to quit: 3 4
```

You can also do some loops:

```bash
python send.py 10.0.4.2
Type space separated switch_ids nums (example: "2 3 2 2 1") or "q" to quit: 2 4 3 1 2 4
```