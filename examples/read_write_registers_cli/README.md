# Read and Write Registers With the CLI


```
+--+      +--+     ++-+
|h1+------+s1+-----+h2+
+--+      +-++     +--+

```

## Introduction

This example shows how to read and write registers using the Runtime CLI.

You can also run into the register by sending packets to the switch. For every
packet that the switch receives it will save in the register the content of the
TOS field at the same index than the TOS. E.g register\[TOS\] = TOS.


## How to run

Start topology

```
sudo p4run
```


Send a packet with a modified tos field from `h1`:

```
mx h1
python send.py 10.0.1.2 50
```

Open CLI

```
simple_switch_CLI --thrift-port 9090
```

Read the register number 50:

```
RuntimeCmd: register_read MyIngress.tos_register 50
MyIngress.tos_register[50]= 50
```

### Read and write from the CLI

Set register values

```bash
RuntimeCmd: register_write tos_register 0 10
RuntimeCmd: register_write tos_register 1 20
RuntimeCmd: register_write tos_register 2 30
RuntimeCmd: register_write tos_register 3 40
RuntimeCmd: register_write tos_register 4 50
```

Read Registers

```bash
tos_register[0]= 10                            
RuntimeCmd: register_read  tos_register 1      
tos_register[1]= 20                            
RuntimeCmd: register_read  tos_register 2      
tos_register[2]= 30
```

Read bulk

```bash
register_read tos_register
```
