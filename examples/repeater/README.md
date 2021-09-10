# Repeater

```
+----+       +----+         +----+
| h1 +-------+ s1 +---------+ h2 |
+----+       +----+         +----+
```

# Introduction

The program simply forwards packets form ports 1 to 2 and viceversa.

# How to run

To start the topology with the P4 switches:
```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Run the receiving script at `h2`:
```bash
mx h2
python receive.py
```

Send packets from `h1`:
```bash
mx h1
python send 10.0.0.2 "hi h2"
```