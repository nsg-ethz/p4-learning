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

In the ECMP example, we used a very basic (but widely used) technique to load balance traffic across
multiple equal cost paths. ECMP works very well when it has to load balance many small flows with similar sizes (since it
randomly maps them to one of the possible paths). However, real traffic does not look as described above, real traffic is composed by many
small flows, but also but very few that are quite bigger. This makes ECMP suffer from a well-known performance problem such as hash collisions,
in which few big flows end up colliding in the same path. In this example use state and information provided by the simple_switch's
`standard_metadata` to fix the collision problem of ECMP, by implementing flowlet switching on top.

Flowlet switching leverages the burstness of TCP flows to achieve a better load balancing. TCP flows tend to come in bursts (for instance because
a flow needs to wait to get window space). Every time there is gap which is big enough (i.e., 50ms) between packets from the same flow, flowlet switching
will rehash the flow to another path (by hashing an ID value together with the 5-tuple).

For more information about flowlet switching check out this [paper](https://www.usenix.org/system/files/conference/nsdi17/nsdi17-vanini.pdf)