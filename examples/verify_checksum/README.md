# Verifying a checksum


```
+--+      +--+     ++-+
|h1+------+s1+-----+h2+
+--+      +-++     +--+

```

## Introduction

In this example we show how to verify IPv4 checksums and drop packets accordingly.

### How to run

Start the topology:
```bash
sudo p4run
```

or
```bash
sudo python network.py
```

Start a receiver at `h2`:
```bash
mx h2
python receive.py
```

Send valid and invalid packets to `h2` from `h1`:
```bash
mx h1
python send.py 10.0.1.2 valid/invalid
```

You will observe that only packets with a valid checksum get forwarded.
