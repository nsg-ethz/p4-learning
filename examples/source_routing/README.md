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