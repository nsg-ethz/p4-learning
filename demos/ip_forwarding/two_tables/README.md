# Hierarchical Forwarding

```


                   +--+
            +------+s2+------+
            |      +--+      |
+--+      +-++              ++-+       +--+--+
|h1+------+s1|              |s4+-------+h2/h3|
+--+      +-++              ++-+       +--+--+
            |                |
            |      +--+      |
            +------+s3+------+
                   +--+


```


## How to run

Run the topology:

```
sudo p4run
```

Runs controller and populates 50k entries:
```
sudo python controller populate 50000
```

Try to ping from one host to another:

```
mininet> h1 ping h2
```


Simultaneously ping h2 and h3

```
mx h1
ping 10.0.2.2

#another terminal
mx h1
ping 10.250.250.2
```

To fail the link between s1 and s2

```
mininet> link s1 s2 down
```

Update the switch so it reroutes the traffic and see how
long does it take until h2 and h3 are reachable again.
