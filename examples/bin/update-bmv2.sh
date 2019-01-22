#! /bin/bash

#save current path to return later
CURRENT_PATH="$(pwd)"

#enable multi-queueing
if [[ $* == *--hard-clean* ]]
then
    sudo rm -rf $HOME/p4/bmv2
    cd $HOME/p4
    git clone https://github.com/p4lang/behavioral-model bmv2
    cd bmv2
else
    #change directory to the directory where p4-bmv2 is
    #assumes that bmv2 is installed here:
    cd $HOME/p4/bmv2
    # Clean repo
    make clean

    # Pull new changes
    git pull


#enable multi-queueing
if [[ $* == *--enable-multi-queue* ]]
then
    sed -i 's/^\/\/ \#define SSWITCH_PRIORITY_QUEUEING_ON/\#define SSWITCH_PRIORITY_QUEUEING_ON/g' targets/simple_switch/simple_switch.h
elif [[ $* == *--disable-multi-queue* ]]
then
    sed -i 's/^\#define SSWITCH_PRIORITY_QUEUEING_ON/\/\/ \#define SSWITCH_PRIORITY_QUEUEING_ON/g' targets/simple_switch/simple_switch.h
fi

#install dependencies again
#./install_deps.sh

# Compile and install
./autogen.sh

if [[ $* == *--no-debug* ]]; then
    ./configure --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'
else

    # With debug enabled in binaries:
    ./configure 'CXXFLAGS=-O0 -g'
    # Without debug enabled:
    #./configure
fi

make -j 20
#install
sudo make install
sudo ldconfig

