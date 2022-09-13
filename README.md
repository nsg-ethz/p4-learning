# P4-Learning

This repository contains a compilation of useful resources for data plane programming, specially for the ones wanting to learn how to write **P4-16** programs and test them in a virtual environment. All the exercises and examples provided are designed to work with *P4-Utils*, a testing and prototyping framework available [here](https://github.com/nsg-ethz/p4-utils).

A big part of the materials come from the *Advanced Topics in Communication Networks* lecture taught at ETH Zürich. For more information visit our [website](https://adv-net.ethz.ch/).

> **Attention: new update released!**  
> As of 2021, a large update in the *P4-Utils* framework has been released. This entails several improvements that, unfortunately, make the new prototyping platform not backward compatible with the old exercises and examples of this repository. In response to this, *P4-Learning* has been updated too: all the relevant information about the migration from the old to the new version are available [here](#migrate-to-the-new-version).


## What will you find here?

You will find software installation guides, lecture slides, specific development documentation, exercises, a collection of examples and much more. Specifically:
- [Slides](./slides): deck of slides that go from the story of SDN and introduction to data plane programming to advanced (research level) applications.
- [Examples](./examples): a collection of examples showing how to use almost all the simple switch features.
- [Exercises](./exercises): a set of P4 exercises with a long description and solutions.
- [Environment Installation](https://github.com/nsg-ethz/p4-utils/tree/master/vm): a guide and scripts to install the required software to start developing P4 applications in your own machine.

**The documentation of *P4-Learning* is available in the [Wiki](https://github.com/nsg-ethz/p4-learning/wiki).** It contains helpful information that will help you getting started with the exercises and examples contained in this repository. Moreover, you will also find documentation about the software switches used in the network topologies and how to configure them using their control plane.


## Migrate to the new version

The recent update of *P4-Utils* introduced several improvements, affecting also *P4-Learning*. All the exercises and examples have been already migrated to the new version and they are now compatible with the new framework. However, should you have customized examples crafted from the old ones, please make sure that you have ported any controller to Python 3 and that the JSON network configuration file is compliant with the new specification.

> **Notice**  
> Old network JSON configuration files are not compatible with the new version of *P4-Utils*.

You can find further information about the update changelog and how the JSON configuration file specification has changed in the [Wiki](https://github.com/nsg-ethz/p4-learning/wiki/Migrate-to-the-new-version). Moreover, consider that, in the new version of *P4-Utils*, networks can be started also using a Python script and the new `NetworkAPI`.


## Getting started


### Clone this repository into your machine

If you already have the required software and you want to solve the exercises, run the examples or simply download the content, get a local copy of this repository in your machine:

```bash
git clone https://github.com/nsg-ethz/p4-learning.git
```

We will periodically add new content to this repository (specially documentation and new examples), so make sure to check it regularly or `git pull` it from your machine.

> **Notice**  
> In case you have not installed the dependencies, make sure to check out [this section](#install-the-required-software) and follow the instructions.


### Install the required software

*P4-Learning* depends on the following software that needs to be installed before any exercises or example can be run. Please refer to these links to build and install it on your device.

- [PI](https://github.com/p4lang/PI)
- [*Behavioral Model* (BMv2)](https://github.com/p4lang/behavioral-model)
- [P4C](https://github.com/p4lang/p4c)
- [*Mininet*](http://mininet.org/)
- [*FRRouting*](https://frrouting.org/)
- [*P4-Utils*](https://github.com/nsg-ethz/p4-utils)

**A more detailed user guide on how to start with *P4-Learning* is available in the [Wiki](https://github.com/nsg-ethz/p4-learning/wiki/Getting-Started).** It contains helpful information about the dependencies and the installation process. Moreover, you will find also instructions on how to use the virtual machine that we provide, so that the cumbersome installation of the various components can be skipped and you can directly start learning P4!
