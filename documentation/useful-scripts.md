# Useful Scripts

In this section we will add scripts that might come handy. For instance, a script to upgrade some of the
software you can find in the VM.


### Installing all the p4-tools that come with the VM

If you just want to install all the software required to start developing
P4 you can use the [install-p4-tools.sh](../vm/bin/install-p4-tools.sh) script.

You can change the two following variables to enable/disable debugging or the
required software for the P4runtime.

```
DEBUG_FLAGS=true
ENABLE_P4_RUNTIME=true
```

### Updating BMV2

We provide a very useful script that allows you to easily update `bmv2` to the latest version,
to a different commit, enable/disable debugging, multiqueuing and more. If you built the `vm`
using vagrant or use the provided VM this script will be already installed in `/bin/` and you
directly used it.

```
update-bmv2 -h

update-bmv2 [OPTION]... [FILE]...

Update bmv2/PI script options.

 Options:
  --enable-multi-queue: Enables simple_switch multiple queues per port
  --update-code:        Before building cleans and pulls code from master or <use-commit>
  --bmv2-commit:        Specific commit we want to checkout before building the bmv2
  --pi-commit:          Specific commit we want to checkout before building PI
  --enable-debugging:   Compiles the switch with debugging options
  --enable-p4runtime:   Compiles the simple_switch_grpc
  ```


You can find the script [here](../vm/bin/update-bmv2.sh).

### Updating P4C

We also provide a similar script to update `p4c`, the P4 code compiler.

```
update-p4c -h

update-p4c [OPTION]... [FILE]...

Update p4c script options.

 Options:
  --update-code          Username for script
  --p4c-commit:          Specific commit we want to checkout before building the bmv2
  --enable-debugging:    Compiles the switch with debugging options
  --copy-p4include:      Copies a custom p4include to the global path
  --only-copy-p4include: Does not compile p4c
```

You can find the script [here](../vm/bin/update-p4c.sh).
