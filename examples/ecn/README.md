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

If the output queue builds up, the P4 switch will tag packets with the ECN flag "11". In order to
verify that you can simply use wireshark.

