# Ternary Match Example

```
+----+       +----+         +----+
| h1 +-------+ s1 +---------+ h2 |
+----+       +----+         +----+
```

# Introduction

Very simple forwarding program that uses a ternary match. See `s1-commands.txt` to see how to populate tables with ternary matches using the CLI API. You will see that matches are of the form `value&mask`, for example: `0x00000000&&&0x80000000`, and the last action parameter is used as priority (lower better).

# How to run

To start the topology with the P4 switches:
```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Check that there is connectivity among hosts by doing:
```
mininet> pingall
```