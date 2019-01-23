# Implementing Basic Forwarding

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

The objective of this exercise is to write a P4 program that
implements basic forwarding but using two tables. This program
is a very simple extension of the `ip_forwarding` example.


## How to run

Run the topology:

```
sudo p4run
```


Try to ping from one host to another:

```
mininet> h1 ping h2
```

Ping from all host pairs to test for connectivity:

```
mininet> pingall
```


