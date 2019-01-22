#!/usr/bin/env bash

apt-get install dos2unix
find /vagrant/bin/ -not -name "*dos2unix.sh" -type f  -print0 | xargs -0 dos2unix
find /vagrant/vm_files/ -not -name "*dos2unix.sh" -type f  -print0 | xargs -0 dos2unix

#provision vm_files after dos2unix
cp /vagrant/vm_files/p4_16-mode.el /home/vagrant/p4_16-mode.el
cp /vagrant/vm_files/p4.vim /home/vagrant/p4.vim
cp /vagrant/vm_files/nsg-logo.png /home/vagrant/nsg-logo.png
cp /vagrant/vm_files/tmux.conf /home/vagrant/.tmux.conf
