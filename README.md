# P4 Learning

This repository contains a compilation of useful resources for data plane programming, specially
for the ones wanting to learn how to write **P4-16** programs and test them in a virtual environment.

A big part of the materials come from the Advanced Topics in Communication Networks lecture taught
at ETH Zurich. For more information visit our [website](https://adv-net.ethz.ch/2019/).

## What will you find here ?

You will find software installation guides, lecture slides, specific development documentation, exercises,
a collection of examples and much more. Specifically:

* [Slides](./slides): deck of slides that go from the story of SDN and introduction to data plane programming to advanced (research level) applications.
* [Documentation](./documentation): list of links and documents with very useful information for P4 development.
* [Examples](./examples): a collection of examples showing how to use almost all the simple switch features.
* [Demos](./demos): a collection of demos with running examples.
* [Exercises](./exercises):A set of P4 exercises with a long description and solutions.
* [Environment Installation](./vm): a guide and scripts to install the required software to start developing P4 applications
in your own machine

## How to start?

### Clone this repository into your machine

If you want to solve the exercises, run the examples or simply download the content get a local copy of this repository in your machine:

```bash
git clone https://github.com/nsg-ethz/p4-learning.git
```

We will periodically add new content to this repository (specially documentation and new examples), so make sure to check it regularly or
`git pull` it from your machine.

### Required Software

In order to be able to compile P4 code, run it in a software switch (bmv2) and
create virtual topologies with hosts, several dependencies and open source tools
need to be installed first.

Since the installation process can be a bit
tedious and cumbersome we provide you with a [Vagrant](https://www.vagrantup.com/intro/index.html)
script that automatically builds a virtual machine with all required software already installed. You can find the VM setup
instructions in the [P4 Virtual Machine Installation](vm/README.md) document.

**Important:** Some exercises or examples will only work (due to bug fixes) if you use the same
version of `bmv2` and `p4c` that we provide. See the following [installation](./vm/bin/install-p4-tools.sh) script and use the
same `commits`.

#### Installing P4-utils

To run the exercises and examples we use [P4 utils](https://github.com/nsg-ethz/p4-utils). P4-utils is an extension to Mininet to support P4 devices.
It was strongly inspired by the original [p4app](https://github.com/p4lang/p4app) from the [p4lang](https://github.com/p4lang) repository.
See the [P4-utils](https://github.com/nsg-ethz/p4-utils) repository for more information.

If you build the VM from the vagrant script we provide or directly download the OVA package you will have `p4-utils` already installed, however
if you already have the required software and use your own machine/VM you can manally install it:

```bash
git clone https://github.com/nsg-ethz/p4-utils.git
cd p4-utils
sudo ./install.sh
```

To update you just simply:

```bash
cd /home/p4/p4-tools/p4-utils
git pull
```

**Note:** at the moment p4-utils does not support the `P4Runtime`, thus all the exercises and examples use the thrift `RuntimeAPI`
(either through the CLI or with p4-utils API).
