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

```
sudo p4run
```


Start a receiver at `h2`:

```
mx h2
python receive.py
```

Send valid and invalid packets to `h2` from `h1`:

```
mx h1
python send.py 10.0.1.2 valid/invalid
```

You will observe that only packets with a valid checksum get forwarded.
