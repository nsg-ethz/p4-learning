#!/usr/bin/env bash

set -xe

BUILD_DIR=~/p4-tools

#Install requirements (a lot of them might be redundant

sudo apt update
sudo apt-get install -y --no-install-recommends \
    autoconf \
    automake \
    bison \
    build-essential \
    cmake \
    cpp \
    curl \
    flex \
    git \
    libavl-dev \
    libboost-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-filesystem-dev \
    libboost-thread-dev \
    libboost-filesystem-dev \
    libboost-program-options-dev \
    libboost-system-dev \
    libboost-test-dev \
    libboost-thread-dev \
    libc6-dev \
    libev-dev \
    libevent-dev \
    libffi-dev \
    libfl-dev \
    libgc-dev \
    libgc1c2 \
    libgflags-dev \
    libgmp-dev \
    libgmp10 \
    libgmpxx4ldbl \
    libjudy-dev \
    libpcap-dev \
    libpcre3-dev \
    libreadline6 \
    libreadline6-dev \
    libssl-dev \
    libtool \
    make \
    pkg-config \
    protobuf-c-compiler \
    python2.7 \
    python2.7-dev \
    tcpdump \
    wget \
    unzip \
    bridge-utils

sudo -H pip install setuptools cffi ipaddr ipaddress pypcap

#commit values from P4 Tutorials
#BMV2_COMMIT="7e25eeb19d01eee1a8e982dc7ee90ee438c10a05"
#P4C_COMMIT="48a57a6ae4f96961b74bd13f6bdeac5add7bb815"
#PI_COMMIT="219b3d67299ec09b49f433d7341049256ab5f512"
#PROTOBUF_COMMIT="v3.2.0"
#GRPC_COMMIT="v1.3.2"

#FROM ONOS
# in case BMV2_COMMIT value is updated, the same variable in
# protocols/bmv2/thrift-api/BUCK file should also be updated
#BMV2_COMMIT="a3f0ebe4c0f10a656f8aa1ad68cb20402a62b0ee"
#P4C_COMMIT="2d089af757212a057c6690998861ef67439305f4"
#PI_COMMIT="7e94b025bac6db63bc8534e5dd21a008984e38bc"
#PROTOBUF_COMMIT="v3.2.0"
#GRPC_COMMIT="v1.3.2"

#Advanced Topics in Communication networks 2018 Commits
#BMV2_COMMIT="7e71a9bdd161afd63a162aaa96703bfa7ab1b3e1" #september 2018
#P4C_COMMIT="5ae30eed11cd6ae2fcd54f01190b9e198f429420" #september 2018
#PI_COMMIT="2b4a3ed73a8168d8adce48654a0f7bfc0fca875c"
#PROTOBUF_COMMIT="v3.2.0"
#GRPC_COMMIT="v1.3.2"

#P4-teaching release commits
BMV2_COMMIT="55713d534ce2d0fb86240b74582f31c15549738b" # Jan 19 2019
P4C_COMMIT="1ab1c796677a3a2349df9619d82831a39a6e4437"  # Jan 18 2019
PI_COMMIT="d338c522428b6256d7390d08781f8df8b204d1ee"   # Jan 16 2019
PROTOBUF_COMMIT="v3.2.0"
GRPC_COMMIT="v1.3.2"

NUM_CORES=`grep -c ^processor /proc/cpuinfo`

mkdir -p ${BUILD_DIR}

# If false, build tools without debug features to improve throughput of BMv2 and
# reduce CPU/memory footprint.
DEBUG_FLAGS=true
ENABLE_P4_RUNTIME=true

#install mininet
function do_mininet {

    cd $HOME

    git clone git://github.com/mininet/mininet mininet
    cd mininet
    sudo ./util/install.sh -nwv
    cd ..
}

#Install Protobuf
function do_protobuf {
    cd ${BUILD_DIR}
    if [ ! -d protobuf ]; then
      git clone https://github.com/google/protobuf.git
    fi
    cd protobuf
    git fetch
    git checkout ${PROTOBUF_COMMIT}

    export CFLAGS="-Os"
    export CXXFLAGS="-Os"
    export LDFLAGS="-Wl,-s"
    ./autogen.sh
    ./configure --prefix=/usr
    make -j${NUM_CORES}
    sudo make install
    sudo ldconfig
    unset CFLAGS CXXFLAGS LDFLAGS

    # force install python module
    cd python
    sudo python setup.py install --cpp_implementation
}

#needed for PI.
function do_grpc {
    cd ${BUILD_DIR}
    if [ ! -d grpc ]; then
      git clone https://github.com/grpc/grpc.git
    fi
    cd grpc
    git fetch
    git checkout ${GRPC_COMMIT}
    git submodule update --init --recursive

    export LDFLAGS="-Wl,-s"
    make -j${NUM_CORES}
    sudo make install
    sudo ldconfig
    unset LDFLAGS

    # Install gRPC Python Package
    sudo pip install -r requirements.txt
    sudo pip install grpcio
    sudo pip install .
}

#needed for PI, this is the same than install_deps.sh but without the first apt-gets
function do_bmv2_deps {
    # BMv2 deps (needed by PI)
    cd ${BUILD_DIR}
    if [ ! -d bmv2 ]; then
        git clone https://github.com/p4lang/behavioral-model.git bmv2
    fi
    cd bmv2
    git checkout ${BMV2_COMMIT}
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
    cd ..
}

#Tentative gNMI support with sysrepo
function do_sysrepo {
    # Dependencies in : https://github.com/p4lang/PI/blob/master/proto/README.md
    sudo apt-get --yes install build-essential cmake libpcre3-dev libavl-dev libev-dev libprotobuf-c-dev protobuf-c-compiler

    cd ${BUILD_DIR}

    # Install libyang
    if [ ! -d libyang ]; then
        git clone https://github.com/CESNET/libyang.git
    fi
    cd libyang
    git checkout v0.16-r1
    mkdir build
    cd build
    cmake ..
    make
    sudo make install
    sudo ldconfig

    cd ../..

    # Install sysrepo
    if [ ! -d sysrepo ]; then
        git clone https://github.com/sysrepo/sysrepo.git
    fi
    cd sysrepo
    git checkout v0.7.5
    mkdir build
    cd build
    cmake -DCMAKE_BUILD_TYPE=Release -DBUILD_EXAMPLES=Off -DCALL_TARGET_BINS_DIRECTLY=Off ..
    make
    sudo make install
    sudo ldconfig
    cd ..
}

#only if we want P4Runtime
function do_PI {
    cd ${BUILD_DIR}
    if [ ! -d PI ]; then
        git clone https://github.com/p4lang/PI.git
    fi
    cd PI
    git fetch
    git checkout ${PI_COMMIT}
    git submodule update --init --recursive
    ./autogen.sh
    if [ "$DEBUG_FLAGS" = true ] ; then
        ./configure --with-proto --with-sysrepo "CXXFLAGS=-O0 -g"
    else
        ./configure --with-proto --with-sysrepo
    fi
    make -j${NUM_CORES}
    sudo make install
    sudo ldconfig
    cd ..
}

function do_bmv2 {

    if [ "$ENABLE_P4_RUNTIME" = false ] ; then
        do_bmv2_deps
    fi

    cd ${BUILD_DIR}
    if [ ! -d bmv2 ]; then
       git clone https://github.com/p4lang/behavioral-model.git bmv2
    fi
    cd bmv2
    git checkout ${BMV2_COMMIT}
    ./autogen.sh

    #./configure 'CXXFLAGS=-O0 -g' --with-nanomsg --with-thrift --enable-debugger
    if [ "$DEBUG_FLAGS" = true ] && [ "$ENABLE_P4_RUNTIME" = true ] ; then
        #./configure --enable-debugger --enable-elogger --with-thrift --with-nanomsg  "CXXFLAGS=-O0 -g"
        ./configure --with-pi --enable-debugger --with-thrift --with-nanomsg --disable-elogger "CXXFLAGS=-O0 -g"

    elif [ "$DEBUG_FLAGS" = true ] && [ "$ENABLE_P4_RUNTIME" = false ] ; then
        ./configure --enable-debugger --enable-elogger --with-thrift --with-nanomsg  "CXXFLAGS=-O0 -g"

    elif [ "$DEBUG_FLAGS" = false ] && [ "$ENABLE_P4_RUNTIME" = true ] ; then
         ./configure --with-pi --without-nanomsg --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'
    else #both false
        #Option removed until we use this commit: https://github.com/p4lang/behavioral-model/pull/673
        #./configure --with-pi --disable-logging-macros --disable-elogger --without-nanomsg
        ./configure --disable-elogger --disable-logging-macros 'CFLAGS=-g -O2' 'CXXFLAGS=-g -O2'

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

function do_p4c {
    cd ${BUILD_DIR}
    if [ ! -d p4c ]; then
        git clone https://github.com/p4lang/p4c.git
    fi
    cd p4c
    git fetch
    git checkout ${P4C_COMMIT}
    git submodule update --init --recursive

    mkdir -p build
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

function do_scapy-vxlan {
    cd ${BUILD_DIR}
    if [ ! -d scapy-vxlan ]; then
        git clone https://github.com/p4lang/scapy-vxlan.git
    fi
    cd scapy-vxlan

    git pull origin master

    sudo python setup.py install
}

function do_scapy {
    # Installs normal scapy
    sudo pip install scapy
}

function do_ptf {
    cd ${BUILD_DIR}
    if [ ! -d ptf ]; then
        git clone https://github.com/p4lang/ptf.git
    fi
    cd ptf
    git pull origin master

    sudo python setup.py install
}

function do_p4-utils {
    cd ${BUILD_DIR}
    if [ ! -d p4-utils ]; then
        git clone https://github.com/nsg-ethz/p4-utils.git
    fi
    cd p4-utils
    sudo ./install.sh
    cd ..
}

# Update scripts
function do_install_scripts {
    mkdir -p /home/p4/bin
    cp /vagrant/bin/update-bmv2.sh /home/p4/bin/update-bmv2
    chmod a+x /home/p4/bin/update-bmv2
    cp /vagrant/bin/update-p4c.sh /home/p4/bin/update-p4c
    chmod a+x /home/p4/bin/update-p4c
}

function do_p4-learning {
    cd ${BUILD_DIR}
    if [ ! -d p4-learning ]; then
        git clone https://github.com/nsg-ethz/p4-learning.git
    fi
    cd ..
}

# Due to this bug: https://github.com/jafingerhut/p4-guide/tree/master/linux-veth-bug
# we need to verify if the current kernel is buggy or not
function do_verify-ubuntu-bug {
    sudo pip install bs4
    sudo python /vagrant/bin/test_veth_intf.py
}

do_protobuf
if [ "$ENABLE_P4_RUNTIME" = true ] ; then
    do_grpc
    do_bmv2_deps
    do_sysrepo
    do_PI
fi
do_bmv2
do_p4c
#The scapy version they use its too old
#do_scapy-vxlan
do_scapy
do_ptf
do_mininet
do_p4-utils
do_install_scripts
do_p4-learning
do_verify-ubuntu-bug

echo "Done with p4-tools install!"