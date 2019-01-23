#!/bin/bash

# SCRIPT: update-p4c.sh
# AUTHOR: Edgar Costa Molero
# DATE:   13.10.2017
# REV:    1.0.0
#
#
# PLATFORM: (Tested Ubuntu 16.04.5)
#
#
# PURPOSE: Script to easily update p4lang/p4c. It allows you to
#          update and rebuild the source code and enable or disable
#          several options.
#
# Options:
#
# --update-code: before building cleans and pulls code from master or <use-commit>
#
# --p4c-commit: specific commit we want to checkout before building the bmv2
#
# --enable-debugging: compiles the switch with debugging options
#
# --copy-p4include: copies a custom p4include to the global path
#
# --only-copy-p4include: does not compile p4c
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

Update p4c script options.

 Options:
  --update-code          Username for script
  --p4c-commit:          Specific commit we want to checkout before building the bmv2
  --enable-debugging:    Compiles the switch with debugging options
  --copy-p4include:      Copies a custom p4include to the global path
  --only-copy-p4include: Does not compile p4c
"
}

# Initialize all the option variables.
# This ensures we are not contaminated by variables from the environment.
P4C_COMMIT=
P4INCLUDE_PATH=
P4INCLUDE_ONLY=0
ENABLE_DEBUGGING=0
UPDATE=0

function do_copy_p4include {
    sudo cp $P4INCLUDE_PATH /usr/local/share/p4c/p4include/
}

function do_update_p4c {

    cd ${ROOT_PATH}
    #clean
    rm -rf build
    mkdir -p build

    #if code needs to be updated we pull: master
    if [ "$UPDATE" == 1 ]; then
        git checkout master
        git pull
        git submodule update --init --recursive
    fi
    if [ "$P4C_COMMIT" ]; then
        git checkout master
        git pull
        #remove submodules?
        rm -rf control-plane/PI
        rm -rf control-plane/p4runtime
        rm -rf test/frameworks/gtest
        git checkout ${P4C_COMMIT}
        git submodule update --init --recursive
    fi

    cd build
    if [ "$DEBUG_FLAGS" = true ] ; then
        cmake .. -DCMAKE_BUILD_TYPE=DEBUG $*
    else
        # Debug build
        cmake ..
    fi

    make -j${NUM_CORES}
    sudo make install
    sudo ldconfig
    cd ../..
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
        --only-copy-p4include)
            P4INCLUDE_ONLY=1
            ;;
        --enable-debugging)
            ENABLE_DEBUGGING=1
            ;;
        --p4c-commit)
            if [ "$2" ]; then
                 P4C_COMMIT=$2
                 shift
             else
                 die 'ERROR: "--p4c-commit" requires a non-empty option argument.'
             fi
             ;;
        --p4c-commit=?*)         # Handle the case of an empty --p4c-commit=
            P4C_COMMIT=${1#*=}
            ;;
        --p4c-commit=)         # Handle the case of an empty --p4c-commit=
            die 'ERROR: "--p4c-commit" requires a non-empty option argument.'
            ;;
        --copy-p4include)
            if [ "$2" ]; then
                 P4INCLUDE_PATH=$2
                 shift
             else
                 die 'ERROR: "--copy-p4include" requires a non-empty option argument.'
             fi
             ;;
        --copy-p4include=?*)         # Handle the case of an empty --copy-p4include=
            P4INCLUDE_PATH=${1#*=}
            ;;
        --copy-p4include=)         # Handle the case of an empty --copy-p4include=
            die 'ERROR: "--copy-p4include" requires a non-empty option argument.'
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
if [[ "$ROOT_PATH" == *"p4c"* ]];then
    if [ "$P4INCLUDE_ONLY" == 0 ]; then
        do_update_p4c
    fi

    if [ "$P4INCLUDE_PATH" ]; then
        do_copy_p4include
    fi
else
    die 'ERROR: you are not in a p4c directory'
fi