# Basic Recirculation


```
+--+      +--+     ++-+
|h1+------+s1+-----+h2+
+--+      +-++     +--+

```

## Introduction

In this example we show how to recirculate packets.

The program itself does nothing. It just recirculates all packets 5 times and
finally sends them to port 2. You can see that we use metadata structs to carry
the recirculate counter in order to track how many times the packet has been recirculated.

The program also shows you a trick to debug programs. De debugging trick
uses a table to match some fields so their value gets displayed in the log
file (`log/s1.log`).

## How to run

Start topology:
```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Send some traffic. And then check the log file at `log/s1.log`, you will see
how the counter increases at each recirculation when matching the `debug` table.

