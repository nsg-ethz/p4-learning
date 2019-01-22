# Heavy Hitter Detection

```
                   +--+
                   |h4|
                   ++-+
                    |
                    |
+--+      +--+     ++-+     +--+
|h1+------+s1+-----+s3+-----+h3|
+--+      +-++     +--+     +--+
            |
            |
          +-++
          |s2|
          +-++
            |
            |
          +-++
          |h2|
          +--+
```

## Introduction

Uses a counting bloom filter to block flows for which the switch has observed more than
a certain number of packets (default 1000).

## Running example

In two different terminals

```
mx h2
python receive.py 5000
```

```
mx h1
python send.py 10.0.2.2 5000 1500
```

