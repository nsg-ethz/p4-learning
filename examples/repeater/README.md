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

```
sudo p4run
```

Run the receiving script at `h2`:

```
mx2
python receive.py
```

Send packets from `h1`:

```
mx h1
python send_receive.py 10.0.1.2 "hi h2"
```