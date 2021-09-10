# L2 Learning

```
+--+      +--+     ++-+
|h1+------+  +-----+h2+
+--+      +  +     +--+
          +s1+
+--+      +  +     ++-+
|h3+------+  +-----+h4+
+--+      +-++     +--+

```

## Introduction

In this example you can see how to use copy to cpu or digests to implement
a l2 learning P4 application and controller. You can find a better explained version
of this example in the [exercises](../../exercises/04-L2_Learning) section.

## How to run

### Copy-to-cpu-based L2 Learning

1. Start the topology (this will also compile and load the program).

   ```
   sudo p4run --conf p4app_cpu.json
   ```
   or
   ```
   sudo python network_cpu.py
   ```

2. Start the controller in another terminal window:

   ```bash
   sudo python l2_learning_controller.py s1 cpu
   ```

   We tell the controller from which switch listen from. The `cpu` parameter tells the controller which technique it should
   use to receive packets. In this case, sniffing an ethernet port.

### Digest-based L2 Learning

1. Start the topology (this will also compile and load the program).

   ```bash
   sudo p4run --conf p4app_digest.json
   ```

   or
   ```bash
   sudo python network_digest.py
   ```

2. Start the controller in another terminal window:

   ```bash
   sudo python l2_learning_controller.py s1 digest
   ```

   We tell the controller from which switch listen from. The `digest` parameter tells the controller which technique it should
   use to receive packets. In this case it will use the `nanomsg` socket to receive digests.