# Exercises

In this page, you find the Advanced Topics in Communication Networks exercises.
Every week we will release a set of exercises.

### Clone this repository to your VM

We use this repository to provide you with all the files that you need to solve the exercises. Use the following commands to get a local clone of the repository _in your VM_ (make sure you are logged in with the user `p4`):

```bash
cd /home/p4/
git clone https://gitlab.ethz.ch/nsg/adv-comm-net-exercises.git
```

### Update local repository to get new tasks and solutions

Remember to pull this repository before every exercise session:

```bash
cd /home/p4/adv-comm-net-exercises
git pull https://gitlab.ethz.ch/nsg/adv-comm-net-exercises.git
```

### Update P4 Utils

P4 utils is under constant development, thus bug fixes or new features can appear from one week to another, keep it updated.

```bash
cd ~/p4-tools/p4-utils
git pull
```

### Documentation

In this repository, you also find useful [documentation](./documentation) that will help you to better understand P4.
We will periodically add new content to the documentation, so make sure you check it regularly (i.e. do `git pull`).

### Required Software

In order to be able to compile p4 code, run it in a software switch and
create topologies with hosts, several dependencies and open source tools need
to be installed.

Since the installation process can be a bit
confusing and cumbersome we provide you with a [Vagrant](https://www.vagrantup.com/intro/index.html)
script that automatically builds a virtual machine with all required software already installed. You can find the VM setup
instructions in the [P4 Virtual Machine Installation](vm/README.md) document.

## Exercises

### Week 1: First contact with P4 (20/09/2018)

 * [Packet Reflector](./exercises/01-Reflector)
 * [Repeater](./exercises/02-Repeater)

### Week 2: Basic L2 Switch (27/10/2018)

 * [Simple L2 Forwarding](./exercises/03-L2_Basic_forwarding)
 * [Broadcasting Packets](./exercises/03-L2_Flooding)
 * [Learning Switch](./exercises/04-L2_Learning)

### Week 3: L3 Switch and Stateful Programming (04/10/2018)

 * [Heavy Hitter Detector](./exercises/06-Heavy_Hitter_Detector)
 * [ECMP](./exercises/05-ECMP)
 * [Flowlet Switching](./exercises/05-Flowlet_Switching)

### Week 4:  Probabilistic Data Structures (11/10/2018)

 * [Count-Min Sketch](../exercises/07-Count-Min-Sketch)

### Week 5: Advanced L3 Features (18/10/2018)

 * [Simple Routing](./exercises/08-Simple_Routing)
 * [Traceroutable Network](./exercises/09-Traceroutable)

### Week 6: (25/10/2018)

 * [Congestion Aware Load Balancing (part 1)](./exercises/10-Congestion_Aware_Load_Balancing)

### Week 7: (1/11/2018)

 * [Congestion Aware Load Balancing (part 2)](./exercises/10-Congestion_Aware_Load_Balancing)