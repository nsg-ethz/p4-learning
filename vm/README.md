# P4 Virtual Machine Installation

In this document we show how to build a VM with all the necessary dependencies and software to 
test and develop P4 applications.

**RECOMMENDED**: We  provide an [OVA image](#download-the-ova-package) that can be simply imported to VirtualBox.

**NOT RECOMMENDED**: If you don't want to use a VM and you already have ubuntu 16.04 installed natively in your laptop you can also install the software manually.
For that you can have a look at [bin](./bin) directory. However you do it at your own risk and we will not be able to help you if something goes
wrong during the installation.

### VM Contents

The VM is based on a Ubuntu 16.04.05 and after building it contains:

* The suite of P4 Tools ([p4lang](https://github.com/p4lang/), [p4utils](https://github.com/nsg-ethz/p4-utils/tree/master/p4utils), etc)
* Text editors with p4 highlighting (sublime, atom, emacs, vim)
* [Wireshark](https://www.wireshark.org/)
* [Mininet](http://mininet.org/) network emulator

## Build the VM using Vagrant

## Requirements

In order to build the VM you need to install the following software:

* [Vagrant](https://www.vagrantup.com/downloads.html)
* [VirtualBox](https://www.virtualbox.org/wiki/Downloads)

Add Vagrant guest additions plugin for better guest/host support.
```bash
vagrant plugin install vagrant-vbguest
```

## Settings

The VM is configured to have 4 GB of RAM, 3 CPUS, and 64 GB of dynamic hard disk. To modify that you can edit the
[Vagrantfile](Vagrantfile) before building. If needed (hopefully not), you can add more disk space to you virtual machine by following the steps
 shown in this [Tutorial](https://tuhrig.de/resizing-vagrant-box-disk-space/).

### Building

```bash
vagrant up
```

> Note: the first time you do `vagrant up` the vm will be built which can take ~1h even with a good internet connection. Once the VM is built
you should reboot it to get the graphical interface.

### Useful Vagrant Commands

* `vagrant status` -- outputs status of the vagrant machine
* `vagrant resume` -- resume a suspended machine (vagrant up works just fine for this as well)
* `vagrant provision` -- forces reprovisioning of the vagrant machine
* `vagrant reload` -- restarts vagrant machine, loads new Vagrantfile configuration
* `vagrant reload --provision` -- restart the virtual machine and force provisioning
* `vagrant halt` -- stops the vagrant machine
* `vagrant suspend` -- suspends a virtual machine (remembers state)
* `vagrant destroy` -- stops and deletes all traces of the vagrant machine

### SSHing into the VM

If you built the VM with vagrant you can ssh into it by running:

```bash
vagrant ssh
```

By default `vagrant ssh` will login as `vagrant` user, however you need to switch ** the user `p4`** in order to be able to use the software.

You can achieve this in multiple ways:

* Modify the `ssh` settings of vagrant. See [ssh_settings](https://www.vagrantup.com/docs/vagrantfile/ssh_settings.html).

* Use the following command to login with the user `p4`:
```bash
ssh p4@localhost -p 2223 #default port we use to forward SSH from host to guest
password: p4
```

* Use `vagrant ssh` to login with the user `vagrant`, then switch to user `p4`:
```bash
vagrant@p4:~$ su p4
```

### VM Credentials

The VM comes with two users, `vagrant` and `p4`, for both the password is the same than the user name. **Always use the user `p4`**.

## Download the OVA Package

Building the vagrant image can take some time. If you want to have an already built VM you can download the Open Virtual 
Appliance (OVA) package and import it with a x86 software virtualizer that supports the format (this has been tested with VirtualBox only).

Pre-built OVA package: [ova](https://drive.google.com/open?id=1tubqk0PGIbX759tIzJGXqex08igFfzpD)

**Note:** During the course we might need to update the OVA package.

## Manual Installation

In case you want to use an already existing VM or you just want to manually install all the dependencies
and required software to run virtual networks with p4 switches, you can have a look at the install [scripts](./bin) used
by the Vagrant setup.

If you are using Ubuntu 16.04.5, you can simply copy all the scripts in `/bin` to your machine/VM and run then run the `root-bootstrap.sh` script. However,
before doing that you will have to copy all the files in `./vm_files` to your home directory, and edit all the lines in the scripts that try to use them. Finally, run
the boostrap script:

```
sudo root-bootstrap.sh
```

## FAQ

#### How to change the keyboard layout?
run this command in the terminal: 
```bash
sudo dpkg-reconfigure keyboard-configuration
```

#### `Vagrant Up` hangs

When you do the first `vagrant up` the ubuntu VM first runs `apt-get update`
which for some reason does not work with some old vagrant `boxes` if you happen
to ran into that problem try to update your boxes with `vagrant box update`.