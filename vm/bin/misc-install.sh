#!/usr/bin/env bash

set -xe

#Install mininet

cd $HOME

git clone git://github.com/mininet/mininet mininet
cd mininet
sudo ./util/install.sh -nwv
cd ..

#install tmux

sudo apt-get remove -y tmux
sudo apt-get -y --no-install-recommends install libncurses5-dev libncursesw5-dev

wget https://github.com/tmux/tmux/releases/download/2.6/tmux-2.6.tar.gz
tar -xvf tmux-2.6.tar.gz

cd tmux-2.6
./configure && make
sudo make install
sudo mv /home/vagrant/.tmux.conf ~/
sudo chown p4:p4 /home/p4/.tmux.conf

cd ..

