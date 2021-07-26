# P4-Learning

This repository contains a compilation of useful resources for data plane programming, specially for the ones wanting to learn how to write **P4-16** programs and test them in a virtual environment. All the exercises and examples provided are designed to work with *P4-Utils*, a testing and prototyping framework available [here](https://github.com/nsg-ethz/p4-utils).

A big part of the materials come from the *Advanced Topics in Communication Networks* lecture taught at ETH Zürich. For more information visit our [website](https://adv-net.ethz.ch/).

> **Attention: new update released!**  
> As of 2021, a large update in the *P4-Utils* framework has been released. This entails several improvements that, unfortunately, make the new prototyping platform not backward compatible with the old exercises and examples contained in this repository. To overcome this problem, *P4-Learning* has been updated too. Please find all the relevant information about the migration from the old to the new version [here](#migrate-to-the-new-version).

## What will you find here?

You will find software installation guides, lecture slides, specific development documentation, exercises, a collection of examples and much more. Specifically:
- [Slides](./slides): deck of slides that go from the story of SDN and introduction to data plane programming to advanced (research level) applications.
- [Documentation](./documentation): list of links and documents with very useful information for P4 development.
- [Examples](./examples): a collection of examples showing how to use almost all the simple switch features.
- [Exercises](./exercises): a set of P4 exercises with a long description and solutions.
- [Environment Installation](./vm): a guide and scripts to install the required software to start developing P4 applications in your own machine.

## Migrate to the new version

The recent update of *P4-Utils* introduced several improvements, affecting also *P4-Learning*. Hereafter, we list the most important ones.
- The application is now fully based on Python 3.
- The legacy JSON configuration file used to start the network has been simplified.
- The network can now be started also using a Python script and the new API.
- *P4Runtime* is currently available with a new API.
- The legacy *Thrift* API and client have been kept for compytibility reasons.

> **Notice**  
> *P4Runtime* is only partially available because of some bugs in the implementation of [*PI*](https://github.com/p4lang/PI), the gRPC server used by the software switches provided by [bmv2](https://github.com/p4lang/behavioral-model). In particular, consider that registers currently cannot be read or written using the *P4Runtime* API.

All the exercises and examples have been already migrated to the new version and they are now compatible with the new framework. However, should you have customized examples crafted from the old ones, please make sure that you have ported any controller to Python 3 and that the JSON network configuration file is compliant with the new specification.

## Getting started

### Clone this repository into your machine

If you want to solve the exercises, run the examples or simply download the content get a local copy of this repository in your machine:
```bash
git clone https://github.com/nsg-ethz/p4-learning.git
```

We will periodically add new content to this repository (specially documentation and new examples), so make sure to check it regularly or `git pull` it from your machine.

### Check out the Wiki

The documentation of *P4-Learning* is available in the [Wiki](https://github.com/nsg-ethz/p4-learning/wiki). It contains helpful information that will help you getting started with the exercises and examples contained in this repository. Moreover, you will find documentation about the software switches used in the network topologies and how to configure them using their control plane.

### Required Software

In order to be able to compile P4 code, run it in a software switch (bmv2) and create virtual topologies with hosts, several dependencies and open source tools need to be installed first.

Since the installation process can be a bit tedious and cumbersome we provide you with a [Vagrant](https://www.vagrantup.com/intro/index.html) script that automatically builds a virtual machine with all required software already installed. You can find the VM setup instructions in the [P4 Virtual Machine Installation](vm/README.md) document.

> **Important**  
> Some exercises or examples will only work (due to bug fixes) if you use the same version of `bmv2` and `p4c` that we provide. See the following [installation](./vm/bin/install-p4-tools.sh) script and use the same `commits`.

#### *P4-Utils*

To run the exercises and examples we use [*P4-Utils*](https://github.com/nsg-ethz/p4-utils), an extension to *Mininet* to support P4 devices. It was strongly inspired by the original [*p4app*](https://github.com/p4lang/p4app) from the [p4lang](https://github.com/p4lang) repository.

If you build the VM from the vagrant script we provide or directly download the OVA package you will have *P4-Utils* already installed, however if you already have the required software and use your own machine/VM you can manally install it:
```bash
git clone https://github.com/nsg-ethz/p4-utils.git
cd p4-utils
sudo ./install.sh
```

To update you just simply run:
```bash
cd /home/p4/p4-tools/p4-utils
git pull
```
