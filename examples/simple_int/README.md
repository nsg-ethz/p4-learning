# Explicit Congestion Notification

```
                 
                   
+--+      +--+     ++-+     
|h1+------+s1+-----+h3+
+--+      +-++     +--+     
            |
            |
          +-++
          |h2|
          +-++
         
```

## Introduction

This example used the Ipv4 options header to store per hop statistics such as switch id, queue depth, output port.

Use the send and receive scripts to be able to parse the options header.
