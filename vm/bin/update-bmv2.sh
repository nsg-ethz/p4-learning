#!/bin/bash

# SCRIPT: update-bmv2.sh
# AUTHOR: Edgar Costa Molero
# DATE:   13.10.2017
# REV:    1.0.0
#
#
# PLATFORM: (Tested Ubuntu 16.04.5)
#
#
# PURPOSE: Script to easily update p4lang/bmv2. It allows you to
#          update and rebuild the source code and enable or disable
#          several options.
#
# Options:
#
# --enable-multi-queue: enables simple_switch multiple queues per port
#
# --update-code: before building cleans and pulls code from master or <use-commit>
#
# --bmv2-commit: specific commit we want to checkout before building the bmv2
#
# --pi-commit: specific commit we want to checkout before building PI
#
# --enable-debugging: compiles the switch with debugging options
#
# --enable-p4runtime: compiles the simple_switch_grpc
#
#
#
# This script must be run from the bmv2 directory!!!

ROOT_PATH="$(pwd)"
NUM_CORES=`grep -c ^processor /proc/cpuinfo`

function die() {
    printf '%s\n' "$1" >&2
    exit 1
}

programname=$0
function usage() {
  echo -n "${programname} [OPTION]... [FILE]...

Update bmv2/PI script options.

 Options:
  --enable-multi-queue: Enables simple_switch multiple queues per port
  --update-code:        Before building cleans and pulls code from master or <use-commit>
  --bmv2-commit:        Specific commit we want to checkout before building the bmv2
  --pi-commit:          Specific commit we want to checkout before building PI
  --enable-debugging:   Compiles the switch with debugging options
  --enable-p4runtime:   Compiles the simple_switch_grpc
"
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
BMV2_COMMIT=
PI_COMMIT=
ENABLE_MULTIQUEUEING=0
ENABLE_DEBUGGING=0
ENABLE_P4_RUNTIME=0
UPDATE=0

# Reinstall bmv2 dependencies. We avoid using install_deps.sh script
# to avoid installing python-pip
function do_bmv2_deps {
    # BMv2 deps (needed by PI)
    cd ${ROOT_PATH}
    # From bmv2's install_deps.sh, we can skip apt-get install.
    # Nanomsg is required by p4runtime, p4runtime is needed by BMv2...
    tmpdir=`mktemp -d -p .`
    cd ${tmpdir}
    bash ../travis/install-thrift.sh
    bash ../travis/install-nanomsg.sh
    sudo ldconfig
    bash ../travis/install-nnpy.sh
    cd ..
    sudo rm -rf $tmpdir
}

function do_update_PI {

    # Assumes PI is one directory behind. If not this will just add PI there.
    # It also assumes that all the PI dependencies are already installed
    cd ..
    if [ ! -d PI ]; then
        git clone https://github.com/p4lang/PI.git
        cd PI
    else
        cd PI
        make clean
    fi

    #if code needs to be updated we pull
    if [ "$UPDATE" == 1 ]; then
        git checkout master
        git pull
    fi

    if [ "$PI_COMMIT" ]; then
        git checkout master
        git pull
        git checkout ${PI_COMMIT}
    fi

    #update submodules
    git submodule update --init --recursive

    ./autogen.sh

    if [ "$ENABLE_DEBUGGING" == 1 ] ; then
        ./configure --with-proto --with-sysrepo "CXXFLAGS=-O0 -g"
    else
        ./configure --with-proto --with-sysrepo
    fi
    make -j${NUM_CORES}
    sudo make install
    sudo ldconfig
    cd ${ROOT_PATH}
}

function do_update_bmv2 {

    cd ${ROOT_PATH}
    pwd
    # Clean previous build
    make clean

    #if code needs to be updated we pull
    if [ "$UPDATE" == 1 ]; then
        git checkout master
        git pull
    fi

    if [ "$BMV2_COMMIT" ]; then
        git checkout master
        git pull
        git checkout ${BMV2_COMMIT}
    fi

    # Try to install dependencies again
    # just in case there is anything new
    do_bmv2_deps

    ./autogen.sh

    # Uncomment simple_switch queueing file to enable multiqueueing
    if [ "$ENABLE_MULTIQUEUEING" == 1 ]; then
        sed -i 's/^\/\/ \#define SSWITCH_PRIORITY_QUEUEING_ON/\#define SSWITCH_PRIORITY_QUEUEING_ON/g' targets/simple_switch/simple_switch.h
    else
        sed -i 's/^\#define SSWITCH_PRIORITY_QUEUEING_ON/\/\/ \#define SSWITCH_PRIORITY_QUEUEING_ON/g' targets/simple_switch/simple_switch.h
    fi

    # TODO: update p4include/v1mode.p4
    # Add:
    # @alias("queueing_metadata.qid")           bit<5>  qid;
    # @alias("intrinsic_metadata.priority")     bit<3> priority;

    #./configure 'CXXFLAGS=-O0 -g' --with-nanomsg --with-thrift --enable-debugger
    if [ "$ENABLE_DEBUGGING" == 1 ] && [ "$ENABLE_P4_RUNTIME" = true ] ; then
        #./configure --enable-debugger --enable-elogger --with-thrift --with-nanomsg  "CXXFLAGS=-O0 -g"
        ./configure --with-pi --enable-debugger --with-thrift --with-nanomsg --disable-elogger "CXXFLAGS=-O0 -g"

    elif [ "$ENABLE_DEBUGGING" = true ] && [ "$ENABLE_P4_RUNTIME" = false ] ; then
        ./configure --enable-debugger --enable-elogger --with-thrift --with-nanomsg  "CXXFLAGS=-O0 -g"

    elif [ "$ENABLE_DEBUGGING" = false ] && [ "$ENABLE_P4_RUNTIME" = true ] ; then
         ./configure --with-pi --without-nanomsg --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'
    else #both false
        #Option removed until we use this commit: https://github.com/p4lang/behavioral-model/pull/673
        #./configure --with-pi --disable-logging-macros --disable-elogger --without-nanomsg
        ./configure --without-nanomsg --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'
    fi

    make -j${NUM_CORES}
    sudo make install
    sudo ldconfig

    # Simple_switch_grpc target
    if [ "$ENABLE_P4_RUNTIME" = true ] ; then
        cd targets/simple_switch_grpc
        ./autogen.sh

        if [ "$DEBUG_FLAGS" = true ] ; then
            ./configure --with-sysrepo --with-thrift "CXXFLAGS=-O0 -g"
        else
            ./configure --with-sysrepo --with-thrift
        fi

        make -j${NUM_CORES}
        sudo make install
        sudo ldconfig
        cd ../../..
    fi
}

# Parsers command line arguments
while true ; do
    case $1 in
        -h|-\?|--help)
            usage    # Display a usage synopsis.
            exit
            ;;
        --update-code)
            UPDATE=1
            ;;
        --enable-multiqueue)
            ENABLE_MULTIQUEUEING=1
            ;;
        --enable-debugging)
            ENABLE_DEBUGGING=1
            ;;
        --enable-p4runtime)
            ENABLE_P4_RUNTIME=1
            ;;
        --bmv2-commit)
            if [ "$2" ]; then
                 BMV2_COMMIT=$2
                 shift
             else
                 die 'ERROR: "--bmv2-commit" requires a non-empty option argument.'
             fi
             ;;
        --bmv2-commit=?*)         # Handle the case of an empty --bmv2-commit=
            BMV2_COMMIT=${1#*=}
            ;;
        --bmv2-commit=)         # Handle the case of an empty --bmv2-commit=
            die 'ERROR: "--bmv2-commit" requires a non-empty option argument.'
            ;;
        --pi-commit)
            if [ "$2" ]; then
                 PI_COMMIT=$2
                 shift
             else
                 die 'ERROR: "--pi-commit" requires a non-empty option argument.'
             fi
             ;;
        --pi-commit=?*)         # Handle the case of an empty --pi-commit=
            PI_COMMIT=${1#*=}
            ;;
        --pi-commit=)         # Handle the case of an empty --pi-commit=
            die 'ERROR: "--pi-commit" requires a non-empty option argument.'
            ;;
        -?*)
            printf 'WARN: Unknown option (ignored): %s\n' "$1" >&2
            ;;
        *)               # Default case: No more options, so break out of the loop.
            break
    esac
    shift
done

# main

# checks if the current path includes the word p4c somewhere
# its probably not the best way to check if we are in the right
# path, but its something
if [[ "$ROOT_PATH" == *"bmv2"* ]];then

    if [ "$ENABLE_P4_RUNTIME" == 1 ]; then
        # Updates PI: https://github.com/p4lang/PI
        do_update_PI
    fi
    do_update_bmv2
else
    die 'ERROR: you are not in a bmv2 directory'
fi
